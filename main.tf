provider "aws" {
	region  = var.region
	version = "~> 3.1"
}

resource "aws_eip" "elastic_ip_address" {
  vpc      = true
}