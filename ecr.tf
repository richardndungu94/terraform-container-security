# ECR Repository - Private container registry
resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-app-${random_string.suffix.result}"
  image_tag_mutability = "IMMUTABLE" # Security: Tags can't be overwritten

  # Enable image scanning on push
  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  # Enable encryption at rest
  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "${var.project_name}-app-repo"
    Description = "Container images with automated security scanning"
  }
}

# ECR Lifecycle Policy - Delete old images
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECR Repository Policy - Who can pull images
resource "aws_ecr_repository_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPullFromECS"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      },
      {
        Sid    = "AllowPushFromCodeBuild"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      }
    ]
  })
}

# CloudWatch Log Group for ECR scanning results
resource "aws_cloudwatch_log_group" "ecr_scan" {
  name              = "/aws/ecr/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-ecr-scan-logs"
  }
}

# EventBridge rule to capture ECR scan findings
resource "aws_cloudwatch_event_rule" "ecr_scan_findings" {
  name        = "${var.project_name}-ecr-scan-findings"
  description = "Capture ECR image scan findings"

  event_pattern = jsonencode({
    source      = ["aws.ecr"]
    detail-type = ["ECR Image Scan"]
    detail = {
      repository-name = [aws_ecr_repository.app.name]
      scan-status     = ["COMPLETE"]
    }
  })

  tags = {
    Name = "${var.project_name}-ecr-scan-rule"
  }
}

# Lambda function to process scan results
resource "aws_lambda_function" "process_scan_results" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "${var.project_name}-process-scan-${random_string.suffix.result}"
  role          = aws_iam_role.lambda_scan_processor.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 60

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SEVERITY_THRESHOLD = var.vulnerability_severity_threshold
      SNS_TOPIC_ARN     = aws_sns_topic.security_alerts.arn
    }
  }

  tags = {
    Name = "${var.project_name}-scan-processor"
  }
}

# Create Lambda deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"

  source {
    content  = <<-EOF
import json
import boto3
import os

sns = boto3.client('sns')

def handler(event, context):
    """Process ECR scan results and alert on vulnerabilities"""
    
    detail = event['detail']
    repository = detail['repository-name']
    image_digest = detail['image-digest']
    findings = detail.get('finding-severity-counts', {})
    
    # Count vulnerabilities
    critical = findings.get('CRITICAL', 0)
    high = findings.get('HIGH', 0)
    medium = findings.get('MEDIUM', 0)
    
    severity_threshold = os.environ['SEVERITY_THRESHOLD']
    
    # Determine if we should alert
    should_alert = False
    if severity_threshold == 'CRITICAL' and critical > 0:
        should_alert = True
    elif severity_threshold == 'HIGH' and (critical > 0 or high > 0):
        should_alert = True
    elif severity_threshold == 'MEDIUM' and (critical > 0 or high > 0 or medium > 0):
        should_alert = True
    
    if should_alert:
        message = f"""
🚨 Container Image Security Alert

Repository: {repository}
Image: {image_digest}

Vulnerabilities Found:
  🔴 CRITICAL: {critical}
  🟠 HIGH: {high}
  🟡 MEDIUM: {medium}

Action Required:
- Review vulnerabilities in AWS Console
- Update base image or dependencies
- Re-scan after fixes

View details:
https://console.aws.amazon.com/ecr/repositories/{repository}
"""
        
        sns.publish(
            TopicArn=os.environ['SNS_TOPIC_ARN'],
            Subject=f'⚠️ Container Vulnerabilities Found: {repository}',
            Message=message
        )
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'repository': repository,
            'critical': critical,
            'high': high,
            'medium': medium,
            'alerted': should_alert
        })
    }
EOF
    filename = "index.py"
  }
}

# EventBridge target: Lambda
resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.ecr_scan_findings.name
  target_id = "ProcessScanResults"
  arn       = aws_lambda_function.process_scan_results.arn
}

# Permission for EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_scan_results.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecr_scan_findings.arn
}
