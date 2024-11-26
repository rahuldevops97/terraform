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

