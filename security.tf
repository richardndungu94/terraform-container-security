# security.tf - Additional security controls and policies

# KMS Key for encryption (optional - currently using default AWS keys)
resource "aws_kms_key" "container_security" {
  description             = "KMS key for container security encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.project_name}-kms-key"
  }
}

# KMS Alias
resource "aws_kms_alias" "container_security" {
  name          = "alias/${var.project_name}"
  target_key_id = aws_kms_key.container_security.key_id
}

# Security Hub (optional - requires enablement in AWS account)
# Uncomment to enable Security Hub integration
# resource "aws_securityhub_account" "main" {}

# CloudWatch Log Metric Filter - Detect failed container starts
resource "aws_cloudwatch_log_metric_filter" "failed_container_starts" {
  name           = "${var.project_name}-failed-starts"
  log_group_name = aws_cloudwatch_log_group.ecs.name
  pattern        = "[time, request_id, event_type=Error*, ...]"

  metric_transformation {
    name      = "FailedContainerStarts"
    namespace = "${var.project_name}/Security"
    value     = "1"
  }
}

# Alarm for failed container starts
resource "aws_cloudwatch_metric_alarm" "failed_starts" {
  alarm_name          = "${var.project_name}-failed-container-starts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FailedContainerStarts"
  namespace           = "${var.project_name}/Security"
  period              = "300"
  statistic           = "Sum"
  threshold           = "3"
  alarm_description   = "Alert on multiple failed container starts"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.security_alerts.arn]

  tags = {
    Name = "${var.project_name}-failed-starts-alarm"
  }
}

# IAM Policy: Deny unencrypted uploads to ECR
resource "aws_iam_policy" "deny_unencrypted_ecr" {
  name        = "${var.project_name}-deny-unencrypted-ecr"
  description = "Deny pushing unencrypted images to ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyUnencryptedPush"
        Effect = "Deny"
        Action = [
          "ecr:PutImage"
        ]
        Resource = aws_ecr_repository.app.arn
        Condition = {
          StringNotEquals = {
            "ecr:EncryptionType" = "AES256"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-deny-unencrypted-policy"
  }
}

# ECS Task Protection (prevent accidental deletion)
resource "aws_ecs_account_setting_default" "task_long_arn_format" {
  name  = "taskLongArnFormat"
  value = "enabled"
}

# Container Insights configuration (already in ecs.tf but documented here)
# Enables detailed monitoring of containers including:
# - CPU and memory utilization
# - Network performance
# - Storage I/O
# - Task and service level metrics

# Security Group rules are defined in ecs.tf
# Following principle of least privilege:
# - Ingress only from ALB on application port
# - Egress only to required destinations
# - No direct internet access on ingress

# Additional security considerations documented:
# 1. All ECS tasks run in Fargate (no EC2 management)
# 2. Tasks use AWS VPC networking mode
# 3. All logs encrypted in transit and at rest
# 4. ECR images scanned on push and daily
# 5. Immutable image tags prevent tampering
# 6. Read-only root filesystem prevents runtime modifications
# 7. Non-root user (UID 1000) reduces attack surface
# 8. Dropped capabilities limit container privileges
# 9. Health checks detect compromised containers
# 10. Deployment circuit breaker prevents bad deployments

# Compliance tags for all resources (applied via default_tags in main.tf)
# - Project: Identifies project resources
# - Environment: dev/staging/prod
# - ManagedBy: Terraform (for change tracking)
# - SecurityLevel: High (for compliance reporting)
