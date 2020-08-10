provider "aws" {
	region  = var.region
	version = "~> 3.1"
}

resource "aws_eip" "nat" {
  vpc  = true
	tags = {
    Name = "NAT Elastic IP"
  }
}