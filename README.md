# ipgdemo – Terraform + Ansible Blue/Green CI/CD

This repository implements a reference CI/CD workflow that provisions AWS
infrastructure with Terraform and deploys an NGINX-based sample application with
Ansible. GitHub Actions orchestrates both infrastructure and application
pipelines and performs a simple blue/green cutover after smoke tests succeed.

The design is intentionally modular so that instance sizing, launch templates,
or application configuration changes can be made with pull requests while
keeping infrastructure and configuration-as-code in a single repository.

## Repository layout

```
.
├── .github/workflows/       # GitHub Actions pipelines
│   ├── infra.yml            # Terraform plan/apply workflow
│   └── app.yml              # Ansible deploy + blue/green workflow
├── ansible/                 # Application configuration
│   ├── ansible.cfg
│   ├── collections/
│   │   └── requirements.yml
│   ├── inventories/
│   │   └── dynamic_aws_ec2.yml
│   ├── playbooks/
│   │   ├── deploy.yml
│   │   └── decommission.yml
│   ├── roles/
│   │   └── hello_app/
│   │       ├── tasks/main.yml
│   │       └── templates/
│   └── tests/unit.yml
├── infrastructure/          # Terraform root module and environment vars
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── modules/
│   │   ├── network/
│   │   └── compute/
│   └── env/
│       ├── prod.tfvars
│       └── staging.tfvars
├── scripts/
│   ├── smoke-test.sh        # Curl-based health check
│   └── switch-target-group.sh
└── README.md
```

## Prerequisites

* AWS account with permissions to manage VPC, EC2, ELB, Auto Scaling, IAM,
  CloudWatch and DynamoDB.
* Terraform `>= 1.5.0` and Ansible `>= 8` for local testing.
* An S3 bucket + DynamoDB table for Terraform remote state/locking.
* IAM user or role for GitHub Actions with permissions for the above services.
* AWS CLI configured locally for bootstrapping and troubleshooting.
* The GitHub repository must have Actions enabled.

## Bootstrapping infrastructure

1. **Prepare remote state (recommended).**
   ```bash
   aws s3 mb s3://<your-state-bucket>
   aws dynamodb create-table \
     --table-name terraform-locks \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST
   cp infrastructure/backend.hcl.example infrastructure/backend.hcl
   # edit backend.hcl with your bucket, key, region, and lock table
   ```
2. **Select the environment variables file.** Update
   `infrastructure/env/prod.tfvars` (or create new files per environment) with
   CIDR ranges, instance sizes, and SSH access CIDRs that match your standards.
3. **Provision the stack locally once** to capture initial outputs:
   ```bash
   cd infrastructure
   terraform init -backend-config=backend.hcl
   terraform workspace new prod    # optional, but recommended
   terraform plan -var-file=env/prod.tfvars
   terraform apply -var-file=env/prod.tfvars
   terraform output
   ```
4. **Record the outputs** for use by GitHub Actions:
   * `alb_dns_name` → prepend `http://` and store as `ALB_URL`
   * `alb_listener_arn` → `ALB_LISTENER_ARN`
   * `blue_target_group_arn` → `BLUE_TARGET_GROUP_ARN`
   * `green_target_group_arn` → `GREEN_TARGET_GROUP_ARN`
   * `blue_asg_name` → `BLUE_ASG_NAME`
   * `green_asg_name` → `GREEN_ASG_NAME` (used for rollbacks/manual ops)

The Terraform module creates an internet-facing Application Load Balancer with
blue and green Auto Scaling groups, tagged so Ansible can target them.

## GitHub Actions configuration

Add the following **repository secrets** (Settings → Secrets and variables →
Actions → New repository secret):

| Secret name                | Description |
|----------------------------|-------------|
| `AWS_ACCESS_KEY_ID`        | Access key for the automation IAM user/role |
| `AWS_SECRET_ACCESS_KEY`    | Secret key for the automation IAM user/role |
| `AWS_REGION`               | Region that matches Terraform deployments |
| `ALB_URL`                  | URL used by smoke tests (e.g. `http://<alb_dns>`) |
| `ALB_LISTENER_ARN`         | ARN for the ALB HTTP listener |
| `BLUE_TARGET_GROUP_ARN`    | ARN for the blue target group |
| `GREEN_TARGET_GROUP_ARN`   | ARN for the green target group |
| `BLUE_ASG_NAME`            | Blue Auto Scaling group name (for scale-down) |

Define the following **repository variables** to avoid hard-coded values in the
workflow files and to control when automation is allowed to run:

| Variable name               | Suggested value |
|-----------------------------|-----------------|
| `ENABLE_TERRAFORM_CICD`     | `false` (set to `true` once secrets/backends are ready) |
| `ENABLE_ANSIBLE_CICD`       | `false` (set to `true` once secrets/targets are ready) |
| `TERRAFORM_ENVIRONMENT`     | `prod` (matches `env/prod.tfvars`) |
| `TERRAFORM_BACKEND_CONFIG`  | `backend.hcl` (if using remote state file) |

> ℹ️  Leave `ENABLE_TERRAFORM_CICD` and `ENABLE_ANSIBLE_CICD` at their default
> `false` until the corresponding secrets, backend files, and target resources
> exist; the workflows will be skipped instead of failing. Set them to `true`
> when you are ready for automation to execute.
>
> `TERRAFORM_BACKEND_CONFIG` is optional. When omitted, Terraform will use the
> local backend. When provided, a file with that name must exist in the
> `infrastructure/` directory (see bootstrapping section above).

If you plan to run the Ansible workflow against a different AWS region or
environment, adjust `ansible/inventories/dynamic_aws_ec2.yml` accordingly
(change the `regions` list or add additional filters).

## How the pipelines work

### Infrastructure (`.github/workflows/infra.yml`)

* Runs on pull requests and pushes touching `infrastructure/`.
* Executes `terraform fmt`, `terraform init`, `terraform validate`, and
  `terraform plan` with the environment-specific `.tfvars` file.
* On pull requests, uploads the plan as a sticky PR comment.
* On merge to `main`, automatically runs `terraform apply` using the saved plan
  output.

### Application (`.github/workflows/app.yml`)

* Runs linting (`ansible-lint`) and a dry-run unit playbook on all pushes/PRs.
* On merge to `main`:
  1. Deploys the role to the **green** Auto Scaling group only.
  2. Executes `scripts/smoke-test.sh` against the ALB URL.
  3. Calls `scripts/switch-target-group.sh` to update the listener to forward
     traffic to the green target group.
  4. Scales the blue Auto Scaling group to zero capacity via
     `playbooks/decommission.yml`.
* To roll back, re-run the workflow with `TARGET_COLOR=blue` (manually) or run
  `scripts/switch-target-group.sh blue` followed by a deployment to blue.

The scripts expect AWS CLI credentials (provided via the configured secrets) and
use Terraform outputs stored as GitHub secrets to manipulate the load balancer.

## Making changes

* **Infrastructure tweaks** (e.g., instance size changes) happen under
  `infrastructure/`. Update `env/*.tfvars` for per-environment overrides.
* **Application updates** (HTML template, banner text, packages) live under
  `ansible/roles/hello_app/`. The dynamic inventory groups hosts based on the
  `Deployment` tag, so the workflow can deploy only to the target color.
* **Smoke tests** can be extended by editing `scripts/smoke-test.sh` or replacing
  it with a more comprehensive suite (e.g., pytest hitting the ALB URL).

Submit a pull request; once the enablement variables are set to `true`, GitHub
Actions will run the relevant pipeline(s). Merging to `main` triggers the
automated apply/deploy stages.

## Local testing

Before opening a PR you can run the same checks locally:

```bash
# Terraform
cd infrastructure
terraform fmt -recursive
terraform validate
terraform plan -var-file=env/staging.tfvars

# Ansible
cd ../ansible
ansible-galaxy collection install -r collections/requirements.yml
ansible-lint
ansible-playbook tests/unit.yml --check -i localhost,
```

To deploy manually to a specific color from your workstation:

```bash
ansible-playbook playbooks/deploy.yml \
  -i inventories/dynamic_aws_ec2.yml \
  --limit tag_Deployment_green \
  -e target_color=green
```

After validating, switch traffic:

```bash
export ALB_LISTENER_ARN=... BLUE_TARGET_GROUP_ARN=... GREEN_TARGET_GROUP_ARN=...
scripts/switch-target-group.sh green
```

## Operational tips & extensions

* Protect the `main` branch and require PR approval before Terraform applies or
  blue/green cutovers.
* Add additional Terraform validations (`tflint`, `terraform validate
  -json`) or security scanners as needed.
* Integrate Molecule tests for the Ansible role or Terratest for infrastructure
  regression coverage.
* Consider adding manual approval steps (GitHub environments) before
  `terraform apply` or traffic switching for production environments.
* Store secrets such as database credentials in AWS Systems Manager Parameter
  Store or Secrets Manager; reference them from Ansible roles via the
  `aws_ssm` lookup.
* For immutable deployments, replace Ansible with Packer-built AMIs or
  container images – the blue/green infrastructure pattern remains useful.

## Cleanup

To remove the demo stack:

```bash
cd infrastructure
terraform destroy -var-file=env/prod.tfvars
```

Ensure no additional resources (e.g., DNS records) depend on the load balancer
before destroying the environment.
