# Coinbase Pro Buddy

This repository contains Python scripts for interacting with the [Coinbase Pro API](https://docs.pro.coinbase.com/) and a Terraform project for building the AWS infrastructure to run those scripts.

## AWS Architecture Overview

The Terraform project creates a new VPC with three subnets, one public and two private. The public subnet routes all outbound traffic through an Internet Gateway and contains a NAT Gateway. This NAT Gateway is assigned an elastic IP address, which must be whitelisted when [creating Coinbase API Keys](https://docs.pro.coinbase.com/#authentication). All outbound traffic from the private subnets are routed to the NAT Gateway. The lambda function is deployed within the new VPC and uses the two private subnets.

## Prerequisites

* Python version 3.8.2< installed locally
* Coinbase Pro `view`, `transfer`, and `trade` API keys
* Terraform configured with the proper [AWS Provider authentication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication)

## Usage

### Creating lambda.zip

1. Create a new directory called `lambda` and copy the desired python script into that directory (`get-accounts.py`, `deposit-funds.py`, `order-crypto.py`, or `withdraw-crypto.py`).

2. In a terminal, navigate to the `lambda` directory and run the following command to install the `requests` library:

```
pip3 install requests -t ./
```

3. Within the `lambda` directory, run the following command to generate `lambda.zip` in the parent directory:

```
zip -r ../lambda.zip .
```

After applying the Terraform changes, the API keys need to be updated in the Lambda function. Instead of explicitly defining the keys in the function code or through environment variables, an ideal solution is creating secure SSM parameter strings to store these values.

## License

[MIT](https://choosealicense.com/licenses/mit/)
