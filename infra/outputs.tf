output "alb_dns_name" {
  value       = aws_lb.app_alb.dns_name
  description = "ALB DNS name"
}

output "alb_https_url" {
  value       = "https://${aws_route53_record.app_a_record.fqdn}"
  description = "HTTPS URL for your service"
}

output "certificate_arn" {
  value       = aws_acm_certificate_validation.this.certificate_arn
  description = "Validated ACM certificate ARN"
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "ECR repo url"
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  value = aws_ecs_service.app.name
}

output "task_definition_family" {
  value = aws_ecs_task_definition.app.family
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
