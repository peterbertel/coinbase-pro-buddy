variable "region" {
	type = string
	description = "The default region for the Coinbase Pro API resources"
}

variable "vpc_cidr_block" {
	type = string
	description = "The CIDR block to assign to the new VPC"
}

variable "subnet_a_cidr_block" {
	type = string
	description = "The CIDR block to assign to Subnet A within the Coinbase VPC"
}

variable "subnet_b_cidr_block" {
	type = string
	description = "The CIDR block to assign to Subnet B within the Coinbase VPC"
}

variable "subnet_c_cidr_block" {
	type = string
	description = "The CIDR block to assign to Subnet C within the Coinbase VPC, which is a public subnet"
}

variable "subnet_a_id" {
	type = string
	description = "The subnet to place the NAT Gateway and the Coinbase Lambda function"
}

variable "subnet_b_id" {
	type = string
	description = "An additional subnet for the Coinbase Lambda function"
}

variable "lambda_sg" {
	type = string
	description = "The security group to assign to the Coinbase Lambda function"
}
