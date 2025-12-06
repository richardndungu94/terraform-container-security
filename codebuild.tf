# S3 bucket for build artifacts
resource "aws_s3_bucket" "build_artifacts" {
  bucket = "${var.project_name}-artifacts-${random_string.suffix.result}"

  tags = {
    Name = "${var.project_name}-build-artifacts"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "build_artifacts" {
  bucket = aws_s3_bucket.build_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "build_artifacts" {
  bucket = aws_s3_bucket.build_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CodeBuild project - Secure container build
resource "aws_codebuild_project" "container_build" {
  name          = "${var.project_name}-build-${random_string.suffix.result}"
  description   = "Build and scan container images with security checks"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = 30

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true # Required for Docker
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "ECR_REPOSITORY_URI"
      value = aws_ecr_repository.app.repository_url
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = var.container_image_tag
    }

    environment_variable {
      name  = "VULNERABILITY_THRESHOLD"
      value = var.vulnerability_severity_threshold
    }
  }

  source {
    type      = "NO_SOURCE"
    buildspec = <<-EOF
version: 0.2

phases:
  pre_build:
    commands:
      - echo "Installing security scanning tools..."
      - curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
      - echo "Logging into ECR..."
      - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY_URI
      
  build:
    commands:
      - echo "Building Docker image..."
      - docker build -t $ECR_REPOSITORY_URI:$IMAGE_TAG .
      
      - echo "Scanning image with Trivy..."
      - trivy image --severity $VULNERABILITY_THRESHOLD --exit-code 1 --no-progress $ECR_REPOSITORY_URI:$IMAGE_TAG || SCAN_FAILED=true
      
      - |
        if [ "$SCAN_FAILED" = "true" ]; then
          echo "❌ Security scan failed! Vulnerabilities found."
          echo "Run locally: trivy image --severity HIGH your-image"
          exit 1
        fi
      
      - echo "✅ Security scan passed!"
      
  post_build:
    commands:
      - echo "Pushing image to ECR..."
      - docker push $ECR_REPOSITORY_URI:$IMAGE_TAG
      - echo "Image pushed successfully"
      - printf '[{"name":"app","imageUri":"%s"}]' $ECR_REPOSITORY_URI:$IMAGE_TAG > imagedefinitions.json

artifacts:
  files:
    - imagedefinitions.json

reports:
  security_scan:
    files:
      - trivy-report.json
    file-format: JSON
EOF
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild.name
    }
  }

  tags = {
    Name = "${var.project_name}-build"
  }
}

# CloudWatch Log Group for CodeBuild
resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-codebuild-logs"
  }
}
