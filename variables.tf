variable "region" {
	type = string
	description = "The default region for the Coinbase Pro API resources"
}

variable "subnet_id" {
	type = string
	description = "The subnet to place the NAT Gateway"
}
