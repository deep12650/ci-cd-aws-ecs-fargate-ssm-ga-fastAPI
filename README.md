# FastAPI on ECS Fargate (Existing VPC) — HTTPS (ACM + Route53)

Production-ready scaffold for deploying a FastAPI app to ECS Fargate in an **existing VPC**,
fronted by an **ALB with HTTPS** (ACM certificate + Route53 DNS validation). CI/CD uses
**GitHub Actions OIDC** — no long-lived AWS keys.

## Prereqs
- Existing **VPC** and **public subnets** (with internet access).
- A **public Route53 hosted zone** for your domain.
- GitHub repo for OIDC deployment.

## Terraform variables to set
Required:
- `vpc_id` — e.g. `vpc-0abc123...`
- `public_subnet_ids` — e.g. `["subnet-01...", "subnet-02..."]`
- `hosted_zone_id` — public zone ID, e.g. `Z123EXAMPLE`
- `domain_name` — e.g. `api.example.com`
- `github_repo` — `owner/repo`
- `aws_account_id` — `123456789012`

Optionally change:
- `region` (default `eu-west-1`)
- `project_name`, `environment`, `container_port`, `desired_count`

## Deploy infra
```bash
cd infra
terraform init
terraform apply   -var='vpc_id=vpc-xxxx'   -var='public_subnet_ids=["subnet-aaa","subnet-bbb"]'   -var='hosted_zone_id=Z123EXAMPLE'   -var='domain_name=api.example.com'   -var='github_repo=YOUR_GH_OWNER/YOUR_REPO'   -var='aws_account_id=123456789012'   -auto-approve
```

Outputs to note:
- `alb_https_url` — open this after deploys
- `github_actions_role_arn` — use in GitHub secret `AWS_ROLE_TO_ASSUME`
- `ecr_repository_url`, `ecs_cluster_name`, `ecs_service_name`, `task_definition_family`

## GitHub Actions setup
In your repo → **Settings → Secrets and variables → Actions**:

**Variables**
- `AWS_REGION` = your region (e.g. `eu-west-1`)
- `AWS_ACCOUNT_ID` = your account id
- `ECR_REPOSITORY` = `fastapi-ecs-fargate`
- `ECS_CLUSTER` = Terraform output `ecs_cluster_name`
- `ECS_SERVICE` = Terraform output `ecs_service_name`
- `TASK_DEF_FAMILY` = Terraform output `task_definition_family`
- `CONTAINER_NAME` = `app`
- `CONTAINER_PORT` - `80`

**Secrets**
- `AWS_ROLE_TO_ASSUME` = Terraform output `github_actions_role_arn`

## HTTPS details
- Requests to HTTP (:80) are 301-redirected to HTTPS (:443).
- ACM certificate is requested in-region and DNS-validated automatically.
- Route53 A and AAAA alias records point your `domain_name` to the ALB.

## Notes
- ECS service runs in **public subnets** with public IP for simplicity. You can place
  tasks in private subnets with NAT later and set `assign_public_ip = false`.
- To inject secrets, add `secrets` entries in the task definition (SSM or Secrets Manager ARNs).
- Scale by adjusting `desired_count`, enabling autoscaling policies, and/or increasing CPU/memory.


---

## Using SSM Parameter Store & Secrets Manager

Provide environment variables to your container directly from AWS stores by passing maps of
`ENV_VAR_NAME => ARN` via Terraform vars:

```bash
terraform apply \
  -var='ssm_parameters={EXAMPLE_API_KEY="arn:aws:ssm:eu-west-1:123456789012:parameter/your/secure/param"}' \
  -var='secrets_manager={DB_CREDENTIALS="arn:aws:secretsmanager:eu-west-1:123456789012:secret:your/secret"}' \
  ...
```

The ECS task role is granted read access to those values (scoped to your account/region by default).
For stricter least-privilege, pass explicit ARNs (as above) instead of using broad defaults.

**Inside your app**, the variables appear as normal env vars:
- `EXAMPLE_API_KEY`
- `DB_CREDENTIALS` (if the secret is JSON, parse it in your app; or target a JSON key with a specific ARN suffix).

> Tip: For Secrets Manager JSON keys you can use the valueFrom ARN with `:json-key:your_key` suffix (AWS supports
> JSON key targeting in some SDK/deployment paths), or store separate secrets per value.
