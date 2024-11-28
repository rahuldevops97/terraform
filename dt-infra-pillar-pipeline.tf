# VPC Configuration
resource "aws_vpc" "virtual_network" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "My VPC"
  }
}

# Security Group Configuration
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

# KMS Key for CloudWatch Logs
resource "aws_kms_key" "cloudwatch_key" {
  description = "KMS key for CloudWatch Log Group"
}

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flow-logs"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudwatch_key.arn
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "vpc_flow_logs_role" {
  name = "vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = { Service = "vpc-flow-logs.amazonaws.com" }
        Effect    = "Allow"
      },
    ]
  })
}

# IAM Policy Attachment for VPC Flow Logs Role
resource "aws_iam_policy_attachment" "vpc_flow_logs_policy" {
  name       = "vpc-flow-logs-policy-attachment"
  roles      = [aws_iam_role.vpc_flow_logs_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonVPCFlowLogsRole"
}

# VPC Flow Log Configuration
resource "aws_flow_log" "vpc_flow_logs" {
  log_group_name   = aws_cloudwatch_log_group.vpc_flow_logs.name
  iam_role_arn     = aws_iam_role.vpc_flow_logs_role.arn
  traffic_type     = "ALL"
  vpc_id           = aws_vpc.virtual_network.id
}

# IAM Role for EC2 Instance
resource "aws_iam_role" "ec2_role" {
  name = "ec2-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = { Service = "ec2.amazonaws.com" }
        Effect    = "Allow"
      },
    ]
  })
}

# IAM Instance Profile for EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# EC2 Instance Configuration
resource "aws_instance" "test_instance" {
  ami           = "ami-0c55b159cbfafe1f0" # Replace with a valid AMI ID
  instance_type = "t3.micro"              # EBS-optimized instance type
  monitoring    = true                    # Enable detailed monitoring

  security_groups = [aws_security_group.default.name]
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
