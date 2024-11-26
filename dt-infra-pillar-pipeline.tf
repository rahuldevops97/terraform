# Creating VPC
resource "aws_vpc" "virtual_network" {
  cidr_block           = "192.168.0.0/24"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "Own_Net"
  }
}

# Default Security Group with restricted traffic
resource "aws_security_group" "default_sg" {
  vpc_id = aws_vpc.virtual_network.id

  # Deny all inbound traffic
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = false
    action      = "deny"  # Deny all traffic
  }

  # Deny all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = false
    action      = "deny"  # Deny all traffic
  }

  tags = {
    Name = "default_security_group"
  }
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "flow_log_role" {
  name = "flow_log_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Role Policy for VPC Flow Logs
resource "aws_iam_role_policy" "flow_log_policy" {
  name = "flow_log_policy"
  role = aws_iam_role.flow_log_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "logs:CreateLogStream"
        Effect    = "Allow"
        Resource  = "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/vpc/*"
      },
      {
        Action    = "logs:PutLogEvents"
        Effect    = "Allow"
        Resource  = "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/vpc/*:log-stream:*"
      }
    ]
  })
}
