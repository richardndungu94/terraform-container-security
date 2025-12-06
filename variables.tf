variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "container-security"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "container_image_tag" {
  description = "Container image tag to deploy"
  type        = string
  default     = "latest"
}

variable "enable_image_scanning" {
  description = "Enable automatic image scanning on push"
  type        = bool
  default     = true
}

variable "scan_on_push" {
  description = "Scan images automatically when pushed to ECR"
  type        = bool
  default     = true
}

variable "vulnerability_severity_threshold" {
  description = "Fail build if vulnerabilities at or above this severity (CRITICAL, HIGH, MEDIUM)"
  type        = string
  default     = "HIGH"

  validation {
    condition     = contains(["CRITICAL", "HIGH", "MEDIUM", "LOW"], var.vulnerability_severity_threshold)
    error_message = "Severity must be CRITICAL, HIGH, MEDIUM, or LOW."
  }
}

variable "container_cpu" {
  description = "CPU units for container (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "Memory for container in MB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of container instances to run"
  type        = number
  default     = 1
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Health check endpoint"
  type        = string
  default     = "/health"
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Email for security alerts"
  type        = string
  default     = ""
}
