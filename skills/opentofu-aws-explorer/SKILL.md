---
name: opentofu-aws-explorer
description: Explore and manage AWS cloud infrastructure resources using OpenTofu/Terraform
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: cloud-infrastructure
---

## What I do
- Manage AWS infrastructure using OpenTofu/Terraform AWS provider
- Configure compute (EC2, Lambda, ECS), networking (VPC, subnets), storage (S3, EBS), databases (RDS, DynamoDB), and security (IAM, Security Groups)
- Apply AWS Well-Architected Framework best practices

## When to use me
Use when:
- Provisioning AWS infrastructure as code
- Automating AWS resource creation and management
- Implementing multi-tier architectures
- Setting up secure networking and VPC configurations
- Managing IAM roles, policies, and security groups

## Prerequisites
- OpenTofu CLI installed: https://opentofu.org/docs/intro/install/
- Valid AWS account with appropriate permissions
- AWS credentials (access keys or IAM role)
- Basic AWS knowledge

## References
- AWS Provider Registry: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- Latest Provider Version: hashicorp/aws ~> 5.0.0
- AWS Well-Architected Framework: https://docs.aws.amazon.com/wellarchitected/

## Steps

### Step 1: Configure Provider
Create `versions.tf` and `provider.tf`:
```hcl
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0.0" }
  }
  backend "s3" {
    bucket         = "terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = { ManagedBy = "Terraform", Project = var.project_name, Environment = var.environment }
  }
}
```

### Step 2: Configure Authentication
```bash
# Method 1: Environment variables (recommended for dev)
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
export AWS_DEFAULT_REGION="ap-southeast-1"

# Method 2: AWS CLI profile
export AWS_PROFILE="my-profile"

# Method 3: Assume Role (recommended for production)
# Configure in provider.tf with assume_role block
```

### Step 3: Create VPC Networking
**Key pattern**:
```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_nat_gateway" "public" {
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  count         = 2
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route { cidr_block = "0.0.0.0/0", gateway_id = aws_internet_gateway.main.id }
}
```

### Step 4: Create Security Groups
**Key pattern**:
```hcl
resource "aws_security_group" "web" {
  name   = "${var.project_name}-web-sg"
  vpc_id = aws_vpc.main.id

  ingress { from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }
  ingress { from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }
  egress  { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_security_group" "app" {
  name   = "${var.project_name}-app-sg"
  vpc_id = aws_vpc.main.id

  ingress { from_port = 8080, to_port = 8080, protocol = "tcp", security_groups = [aws_security_group.web.id] }
  egress  { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }
}
```

### Step 5: Create EC2 Instances and ALB
**Key pattern**:
```hcl
resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-web-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.web_instance_type
  key_name      = var.ssh_key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web.id]
  }
}

resource "aws_autoscaling_group" "web" {
  vpc_zone_identifier = aws_subnet.public[*].id
  desired_capacity    = 2
  max_size           = 4
  min_size           = 2

  target_group_arns = [aws_lb_target_group.web.arn]

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
}

resource "aws_lb" "web" {
  name               = "${var.project_name}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets           = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check { path = "/health", interval = 30, timeout = 5 }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action { type = "forward", target_group_arn = aws_lb_target_group.web.arn }
}
```

### Step 6: Create RDS Database
**Key pattern**:
```hcl
resource "aws_db_instance" "main" {
  identifier             = "${var.project_name}-db"
  engine                 = "mysql"
  engine_version          = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_encrypted      = true
  multi_az               = true

  db_name               = var.db_name
  username              = var.db_username
  password              = var.db_password
  db_subnet_group_name  = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]

  backup_retention_period = 7
  skip_final_snapshot     = false
}
```

### Step 7: Create S3 Bucket
**Key pattern**:
```hcl
resource "aws_s3_bucket" "data" {
  bucket_prefix = "${var.project_name}-data-"
  force_destroy = var.environment == "dev"
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id
  rule { apply_server_side_encryption_by_default { sse_algorithm = "AES256" } }
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}
```

### Step 8: Create IAM Roles
**Key pattern**:
```hcl
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "ec2_policy" {
  name = "${var.project_name}-ec2-policy"
  role = aws_iam_role.ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Action = ["s3:GetObject", "s3:PutObject"], Effect = "Allow", Resource = ["${aws_s3_bucket.data.arn}/*"] }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
```

### Step 9: Define Variables and Outputs
**Key pattern**:
```hcl
variable "aws_region" { description = "AWS region", type = string, default = "ap-southeast-1" }
variable "project_name" { description = "Project name", type = string }
variable "environment" { description = "Environment", type = string }
variable "vpc_cidr" { description = "VPC CIDR", type = string, default = "10.0.0.0/16" }
variable "web_instance_type" { description = "Instance type", type = string, default = "t3.micro" }

output "vpc_id" { description = "VPC ID", value = aws_vpc.main.id }
output "lb_dns_name" { description = "LB DNS", value = aws_lb.web.dns_name }
output "db_endpoint" { description = "DB endpoint", value = aws_db_instance.main.endpoint, sensitive = true }
```

### Step 10: Initialize and Apply
```bash
tofu init
tofu plan -out=tfplan
tofu apply tfplan
tofu output
```

## Best Practices

### Security
- Grant minimal permissions in IAM roles and policies
- Enable encryption at rest and in transit
- Restrict security group access to necessary IPs
- Use MFA for privileged IAM users

### High Availability
- Deploy resources across multiple availability zones
- Use auto scaling groups for compute resources
- Enable multi-AZ for RDS instances
- Configure proper health checks for all services

### Cost Optimization
- Choose appropriate instance types and storage
- Use reserved instances for predictable workloads
- Implement S3 lifecycle policies
- Monitor costs with AWS Cost Explorer

### Networking
- Use separate subnets for tiers (web, app, db)
- Deploy NAT gateways in each AZ
- Use separate route tables for public/private subnets
- Consider VPC peering for inter-VPC communication

### State Management
- Use remote state backends (S3)
- Enable state locking with DynamoDB
- Encrypt state files and enable versioning
- Regularly backup state files

## Common Issues

### Provider Not Found
**Solution**: `tofu init -upgrade` and verify provider source/version.

### Authentication Failed
**Solution**: Verify credentials with `aws sts get-caller-identity` and check environment variables.

### Resource Already Exists
**Solution**: Import existing resource with `tofu import <resource>.<name> <resource_id>`.

### State Lock Error
**Solution**: Check who has lock with `tofu state pull`, then force unlock with `tofu force-unlock <LOCK_ID>` (use caution).
