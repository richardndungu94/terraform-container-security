output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.app.name
}

output "application_url" {
  description = "Application Load Balancer URL"
  value       = "http://${aws_lb.app.dns_name}"
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.app.name
}

output "codebuild_project_name" {
  description = "CodeBuild project name"
  value       = aws_codebuild_project.container_build.name
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "next_steps" {
  description = "What to do next"
  value       = <<-EOT
    ✅ Container Security Pipeline Deployed!
    
    📦 ECR Repository: ${aws_ecr_repository.app.repository_url}
    🌐 Application: http://${aws_lb.app.dns_name}
    
    🚀 Deploy Your Container:
    
    1. Build and push image:
       cd sample-app
       docker build -t ${aws_ecr_repository.app.repository_url}:latest .
       aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.app.repository_url}
       docker push ${aws_ecr_repository.app.repository_url}:latest
    
    2. Trigger CodeBuild:
       aws codebuild start-build --project-name ${aws_codebuild_project.container_build.name}
    
    3. View scan results:
       aws ecr describe-image-scan-findings \
         --repository-name ${aws_ecr_repository.app.name} \
         --image-id imageTag=latest
    
    4. Test application:
       curl http://${aws_lb.app.dns_name}/health
    
    📊 Monitoring:
      Dashboard: ${aws_cloudwatch_dashboard.main.dashboard_name}
      Logs: /ecs/${var.project_name}
    
    🔒 Security Features Enabled:
      ✓ Image scanning on push
      ✓ Encrypted registry
      ✓ Non-root container user
      ✓ Read-only filesystem
      ✓ Dropped capabilities
      ✓ Security alerts via SNS
      ✓ Container Insights
  EOT
}
