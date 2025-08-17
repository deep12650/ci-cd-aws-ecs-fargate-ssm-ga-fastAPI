variable "project_name" {
  description = "Base name for all resources"
  type        = string
  default     = "fastapi-ecs-fargate"
}

variable "environment" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region for ALB/ECS/ACM"
  type        = string
  default     = "eu-west-1"
}

variable "container_port" {
  description = "Container port your app listens on"
  type        = number
  default     = 8000
}

variable "desired_count" {
  description = "Number of tasks to run"
  type        = number
  default     = 2
}

# --- Existing networking ---
variable "vpc_id" {
  description = "Existing VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs (2+ recommended)"
  type        = list(string)
}

# --- DNS + TLS ---
variable "hosted_zone_id" {
  description = "Route53 Hosted Zone ID for the domain (public zone)"
  type        = string
}

variable "domain_name" {
  description = "FQDN for the service, e.g. api.example.com"
  type        = string
}

# --- GitHub OIDC integration ---
variable "github_repo" {
  description = "GitHub repo in the form owner/repo for OIDC trust"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

# --- Secure configuration via SSM Parameter Store & Secrets Manager ---
# Map of ENV_VAR_NAME => SSM Parameter ARN (SecureString or String). Use full ARNs.
variable "ssm_parameters" {
  type        = map(string)
  description = "Map of ENV var to SSM Parameter ARN (valueFrom)."
  default     = {}
}

# Map of ENV_VAR_NAME => Secrets Manager Secret ARN (supports specific version/JSON key ARNs)
variable "secrets_manager" {
  type        = map(string)
  description = "Map of ENV var to Secrets Manager Secret ARN (valueFrom)."
  default     = {}
}
