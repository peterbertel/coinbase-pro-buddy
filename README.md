# Coinbase Pro Buddy

This repository contains Python scripts for interacting with the [Coinbase Pro API](https://docs.pro.coinbase.com/) and a Terraform project for building the AWS infrastructure to run those scripts.

## AWS Architecture Overview

The Terraform project creates a new VPC with three subnets, one public and two private. The public subnet routes all outbound traffic through an Internet Gateway and contains a NAT Gateway. This NAT Gateway is assigned an elastic IP address, which must be whitelisted when [creating Coinbase API Keys](https://docs.pro.coinbase.com/#authentication). All outbound traffic from the private subnets are routed to the NAT Gateway. The lambda functions are deployed within the new VPC and uses the two private subnets.

The two lambda functions [deposit funds](python-scripts/deposit-funds.py) and [order crypto](python-scripts/order-crypto.py). Using CloudWatch Event Rules, the first lambda function deposits funds on the 1st of every month and the second lambda function orders crypto (BTC, by default) on the 15th of every month.

## Prerequisites

* Python version 3.8.2< installed on the local machine (this is for running the `pip` install for `boto3` in the `Create lambda.zip` section)
* Access to a Coinbase Pro Account and the ability to create `view`, `transfer`, and `trade` API keys
* AWS Console Access for creating SSM Parameters
* VPC and Subnet CIDR blocks for a new VPC and subnets in the target AWS account
* Terraform configured with the proper [AWS Provider authentication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication)

## Usage

* [Create lambda.zip](#create-lambdazip)
* [Create terraform.tfvars](#create-terraformtfvars)
* [Apply the Terraform Changes](#apply-the-terraform-changes)
* [Create Coinbase Pro API Keys and SSM Parameters](#create-coinbase-pro-api-keys-and-ssm-parameters)

### Create lambda.zip

1. Within the `python-scripts` directory, create a new directory called `lambda` and copy the `deposit-funds.py` and `order-crypto.py` python scripts into that directory.

2. In a terminal, navigate to the `lambda` directory and run the following command to install the `requests` library:

```
pip3 install requests -t ./
```

3. Within the `lambda` directory, run the following command to generate `lambda.zip` in the parent directory:

```
zip -r ../lambda.zip .
```

### Create terraform.tfvars

Rename [`example-terraform.tfvars`](example-terraform.tfvars) to `terraform.tfvars` and update each of the variables accordingly. Review [`variables.tf`](variables.tf) for descriptions of these variables.

### Apply the Terraform Changes

The Terraform project only requires `lambda.zip` to be created in the target AWS account. Apply the changes and complete the remaining steps.

### Create Coinbase Pro API Keys and SSM Parameters

For each type of API Key (`View`, `Transfer`, and `Trade`), complete the following steps:

* Navigate to the `API` page in Coinbase Pro and click `+ New API Key` to begin creating a new API key.
* For the `Portfolio` entry, use the `Default Portfolio`
* Set a new nickname for the API key (i.e.: `aws_view`, `aws_trade`, etc.)
* Select the correct API Permission checkbox (`View`, `Transfer`, or `Trade`)
* Update the `Passphrase` value if desired
* Reference the Terraform `apply` output or navigate to the AWS account to find the value of the Elastic IP Address created by the project and enter this IP Address into the `IP Whitelist` section of the `Add an API Key` dialog box
* Copy the `Passphrase`
* Navigate to Systems Manager - Parameter Store in the AWS account and create a new SSM Parameter with the following information:
	* Set the `Name` to be `/coinbase/api_pass/API_PERMISSION`, where `API_PERMISSION` is either `view`, `transfer`, or `trade`
	* Select `SecureString` as the `Type`
	* For the `KMS Key Source`, leave the checkbox as `My current account`
	* In the `KMS Key ID` dropdown menu, find the new KMS Key created from the Terraform project (`alias/coinbase_ssm_kms_key`)
	* Set the `Value` to be the `Passphrase` copied from Coinbase Pro
* After creating the SSM Parameter, navigate back to Coinbase Pro and click `CREATE_API_KEY`
* Copy the API secret key displayed
* Create another secure SSM Parameter with similar values as the previous SSM Parameter, setting the name to be `/coinbase/api_secret/API_PERMISSION` and the `Value` to be the API secret key copied from Coinbase Pro
* After creating the SSM Parameter, finish creating the Coinbase Pro API Key
* Find the API key within the list of API Keys and copy the string listed below the `Portfolio` and above the `Nickname` fields - this value is the `api_key`
* Create another secure SSM Parameter with similar values as the previous SSM Parameters, setting the name to be `/coinbase/api_key/API_PERMISSION` and the `Value` to be the API key copied from Coinbase Pro

After creating these SSM Parameters, the Lambda function will be able to execute and retrieve these values during runtime.

## License

[MIT](https://choosealicense.com/licenses/mit/)
