provider "aws" {
	region  = var.region
	version = "~> 3.1"
}

resource "aws_eip" "nat" {
  vpc  = true
	tags = {
    Name = "Coinbase NAT Gateway Elastic IP"
  }
}

resource "aws_nat_gateway" "gateway" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.subnet_id

  tags = {
    Name = "Coinbase NAT Gateway"
  }
}
