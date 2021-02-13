variable "account_id" {
	type        = string
	description = "The AWS account in which to deploy the Coinbase Pro API resources"
}

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
	description = "The CIDR block to assign to Subnet A within the Coinbase VPC, which is a public subnet"
}

variable "subnet_b_cidr_block" {
	type = string
	description = "The CIDR block to assign to Subnet B within the Coinbase VPC"
}

variable "subnet_c_cidr_block" {
	type = string
	description = "The CIDR block to assign to Subnet C within the Coinbase VPC"
}

variable "order_size_in_usd" {
	type = string
	description = "The amount in USD of the selected currency to trade"
}

variable "product_id" {
	type        = string
	description = "The Id of the Coinbase crypto product to order"
	default     = "BTC-USD"
}

variable "product_order_pairs" {
  type        = list(object({
	  product_name = string
		product_id   = string
		order_size   = number
	}))
	default = [
	  {
		  product_name = "bitcoin"
			product_id   = "BTC-USD"
			order_size   = 100
		}
	]
}
