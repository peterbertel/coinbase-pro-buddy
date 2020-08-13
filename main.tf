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

resource "aws_subnet" "coinbase_subnet_a" {
  vpc_id                  = aws_vpc.coinbase_vpc.id
  cidr_block              = var.subnet_a_cidr_block
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Coinbase Subnet A"
  }
}

resource "aws_subnet" "coinbase_subnet_b" {
  vpc_id            = aws_vpc.coinbase_vpc.id
  cidr_block        = var.subnet_b_cidr_block
  availability_zone = "${var.region}b"

  tags = {
    Name = "Coinbase Subnet B"
  }
}

resource "aws_subnet" "coinbase_subnet_c" {
  vpc_id            = aws_vpc.coinbase_vpc.id
  cidr_block        = var.subnet_c_cidr_block
  availability_zone = "${var.region}c"

  tags = {
    Name = "Coinbase Subnet C"
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
  subnet_id     = aws_subnet.coinbase_subnet_a

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
    subnet_ids         = [aws_subnet.coinbase_subnet_b, aws_subnet.coinbase_subnet_c]
    security_group_ids = [var.lambda_sg]
  }
}
