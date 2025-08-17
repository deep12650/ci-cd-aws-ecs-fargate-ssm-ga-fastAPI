// OPTIONAL EXAMPLES — set create_examples = true to provision demo secrets.
// In production, you will typically create parameters/secrets out-of-band.

variable "create_examples" {
  description = "Create example SSM parameter and Secrets Manager secret"
  type        = bool
  default     = false
}

resource "aws_ssm_parameter" "example" {
  count       = var.create_examples ? 1 : 0
  name        = "/${var.project_name}/${var.environment}/EXAMPLE_API_KEY"
  description = "Example API key"
  type        = "SecureString"
  value       = "replace-me"
}

resource "aws_secretsmanager_secret" "example" {
  count      = var.create_examples ? 1 : 0
  name       = "${var.project_name}/${var.environment}/db-credentials"
  description = "Example DB credentials (JSON)"
}

resource "aws_secretsmanager_secret_version" "example" {
  count         = var.create_examples ? 1 : 0
  secret_id     = aws_secretsmanager_secret.example[0].id
  secret_string = jsonencode({ username = "app", password = "replace-me" })
}

// If you enable examples above, you can pass these ARNs via -var on apply, e.g.:
// -var='ssm_parameters={EXAMPLE_API_KEY="${aws_ssm_parameter.example[0].arn}"}'
// -var='secrets_manager={DB_CREDENTIALS="${aws_secretsmanager_secret.example[0].arn}"}'
