provider "aws" {
  region = "us-east-1" # Replace with your desired region
}

# VPC Configuration
resource "aws_vpc" "virtual_network" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "My VPC"
  }
}

# Security Group: Default Restricted
resource "aws_security_group" "default" {
  vpc_id = aws_vpc.virtual_network.id

  # Ingress rules: No inbound traffic allowed
  ingress {
    protocol    = "-1"
    cidr_blocks = []
    description = "No inbound traffic allowed"
  }

  # Egress rules: No outbound traffic allowed
  egress {
    protocol    = "-1"
    cidr_blocks = []
    description = "No outbound traffic allowed"
  }

  tags = {
    Name = "Restricted Default SG"
  }
}

# IAM Role for EC2 Instance Profile
resource "aws_iam_role" "ec2_role" {
  name               = "ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "EC2 IAM Role"
  }
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# EC2 Instance Configuration
resource "aws_instance" "test_instance" {
  ami           = "ami-0c55b159cbfafe1f0" # Replace with a valid AMI ID
  instance_type = "t3.micro"              # EBS-optimized instance type
  monitoring    = true                    # Enable detailed monitoring
  ebs_optimized = true                    # Ensure EBS optimization

  security_groups      = [aws_security_group.default.name]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  metadata_options {
    http_tokens   = "required" # Enforce use of IMDSv2
    http_endpoint = "enabled"
  }

  root_block_device {
    encrypted = true # Encrypt the root volume
  }

  tags = {
    Name = "Test Instance"
  }
}

# KMS Key for CloudWatch Logs
resource "aws_kms_key" "cloudwatch_key" {
  description = "KMS key for CloudWatch Log Group"

  key_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action    = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource  = "*"
      }
    ]
  })

  enable_key_rotation = true
}

# Outputs
output "vpc_id" {
  value = aws_vpc.virtual_network.id
}

output "security_group_id" {
  value = aws_security_group.default.id
}

output "instance_id" {
  value = aws_instance.test_instance.id
}

output "kms_key_id" {
  value = aws_kms_key.cloudwatch_key.id
}
