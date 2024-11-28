resource "aws_security_group" "default" {
  vpc_id = aws_vpc.virtual_network.id

  # Ingress rules: No inbound traffic allowed
  ingress {
    protocol   = "-1"
    cidr_blocks = []
  }

  # Egress rules: No outbound traffic allowed
  egress {
    protocol   = "-1"
    cidr_blocks = []
  }

  tags = {
    Name = "Restricted Default SG"
  }
}


resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name = "/aws/vpc/flow-logs"
}

resource "aws_flow_log" "vpc_flow_logs" {
  log_group_name   = aws_cloudwatch_log_group.vpc_flow_logs.name
  iam_role_arn     = aws_iam_role.vpc_flow_logs_role.arn
  traffic_type     = "ALL"
  vpc_id           = aws_vpc.virtual_network.id
}

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

resource "aws_iam_policy_attachment" "vpc_flow_logs_policy" {
  name       = "vpc-flow-logs-policy-attachment"
  roles      = [aws_iam_role.vpc_flow_logs_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonVPCFlowLogsRole"
}

