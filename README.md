# Coinbase Pro Buddy

This repository contains Python scripts for interacting with the [Coinbase Pro API](https://docs.pro.coinbase.com/) and a Terraform project for building the AWS infrastructure to run those scripts.

## AWS Architecture Overview

The Terraform project creates a new VPC with three subnets, one public and two private. The public subnet routes all outbound traffic through an Internet Gateway and contains a NAT Gateway. This NAT Gateway is assigned an elastic IP address, which must be whitelisted when [creating Coinbase API Keys](https://docs.pro.coinbase.com/#authentication). All outbound traffic from the private subnets are routed to the NAT Gateway. The lambda function is deployed within the new VPC and uses the two private subnets.

## License

[MIT](https://choosealicense.com/licenses/mit/)
