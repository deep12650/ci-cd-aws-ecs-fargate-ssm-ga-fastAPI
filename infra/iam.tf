# ECS task execution assume role
data "aws_iam_policy_document" "ecs_task_execution_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.project_name}-${var.environment}-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.project_name}-${var.environment}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume.json
}

# GitHub OIDC
data "aws_iam_openid_connect_provider" "github" {
  arn = "arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "github_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.project_name}-${var.environment}-gha-oidc-role"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json
}

data "aws_iam_policy_document" "github_permissions" {
  statement {
    sid     = "ECR"
    effect  = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "ECS"
    effect  = "Allow"
    actions = [
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
      "ecs:DescribeServices",
      "ecs:ListTaskDefinitions",
      "ecs:DescribeClusters"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "PassRoles"
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      aws_iam_role.ecs_task_execution_role.arn,
      aws_iam_role.ecs_task_role.arn
    ]
  }
}

resource "aws_iam_policy" "github_policy" {
  name   = "${var.project_name}-${var.environment}-gha-oidc-policy"
  policy = data.aws_iam_policy_document.github_permissions.json
}

resource "aws_iam_role_policy_attachment" "github_attach" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_policy.arn
}


# ---- Allow task to read SSM params and Secrets Manager secrets ----
locals {
  ssm_param_arns  = values(var.ssm_parameters)
  secret_arns     = values(var.secrets_manager)
}

data "aws_iam_policy_document" "task_read_secrets_doc" {
  statement {
    sid    = "ReadSSMParams"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParameterHistory",
      "ssm:DescribeParameters"
    ]
    # If specific ARNs were provided, we use them; otherwise, allow account-scoped access (tighten as needed).
    resources = length(local.ssm_param_arns) > 0 ? local.ssm_param_arns : [
      "arn:aws:ssm:${var.region}:${var.aws_account_id}:parameter/*"
    ]
  }

  statement {
    sid    = "DecryptKMSForSSM"
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = ["*"] # Fine-tune if you use a customer-managed KMS key for your params
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${var.region}.amazonaws.com"]
    }
  }

  statement {
    sid    = "ReadSecretsManager"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = length(local.secret_arns) > 0 ? local.secret_arns : [
      "arn:aws:secretsmanager:${var.region}:${var.aws_account_id}:secret:*"
    ]
  }
}

resource "aws_iam_policy" "task_read_secrets" {
  name   = "${var.project_name}-${var.environment}-task-read-secrets"
  policy = data.aws_iam_policy_document.task_read_secrets_doc.json
}

resource "aws_iam_role_policy_attachment" "task_read_secrets_attach" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.task_read_secrets.arn
}
