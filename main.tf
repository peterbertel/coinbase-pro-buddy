provider "aws" {
	region  = var.region
	version = "~> 3.1"
}

resource "aws_vpc" "coinbase_vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "Coinbase VPC"
  }
}

resource "aws_eip" "nat" {
  vpc  = true
	tags = {
    Name = "Coinbase NAT Gateway Elastic IP"
  }
}

resource "aws_nat_gateway" "gateway" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.subnet_a_id

  tags = {
    Name = "Coinbase NAT Gateway"
  }
}

data "aws_iam_policy_document" "coinbase_lambda_policy_doc" {
  statement {
    sid     = "1"
    effect  = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeNetworkInterfaces"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "coinbase_lambda_policy" {
  name        = "coinbase-lambda-execution-policy"
  description = "The IAM policy for the Coinbase Lambda function"
  policy      = data.aws_iam_policy_document.coinbase_lambda_policy_doc.json
}

resource "aws_iam_role" "coinbase_lambda_role" {
  name               = "coinbase-lambda-execution-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "coinbase-lambda-iam-role-policy-attachment" {
  role       = aws_iam_role.coinbase_lambda_role.name
  policy_arn = aws_iam_policy.coinbase_lambda_policy.arn
}

resource "aws_lambda_function" "coinbase_lambda" {
  filename         = "python-scripts/lambda.zip"
  function_name    = "CoinbaseLambda"
  role             = aws_iam_role.coinbase_lambda_role.arn
  handler          = "get-accounts.lambda_handler"
  source_code_hash = filebase64sha256("python-scripts/lambda.zip")
  runtime          = "python3.8"

  vpc_config {
    subnet_ids         = [var.subnet_a_id, var.subnet_b_id]
    security_group_ids = [var.lambda_sg]
  }
}
