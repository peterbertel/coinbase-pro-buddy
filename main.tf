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

resource "aws_iam_role" "lambda_iam_role" {
  name = "lambda_iam_role"

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

resource "aws_lambda_function" "coinbase_lambda" {
  filename         = "python-scripts/lambda.zip"
  function_name    = "CoinbaseLambda"
  role             = aws_iam_role.lambda_iam_role.arn
  handler          = "get-accounts.lambda_handler"
  source_code_hash = filebase64sha256("python-scripts/lambda.zip")
  runtime          = "python3.8"
}
