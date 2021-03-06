resource "aws_vpc" "coinbase_vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "Coinbase VPC"
  }
}

resource "aws_internet_gateway" "coinbase_igw" {
  vpc_id = aws_vpc.coinbase_vpc.id

  tags = {
    Name = "Coinbase IGW"
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
  subnet_id     = aws_subnet.coinbase_subnet_a.id

  tags = {
    Name = "Coinbase NAT Gateway"
  }
}

resource "aws_route_table" "private_subnet_route_table" {
  vpc_id = aws_vpc.coinbase_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gateway.id
  }

  tags = {
    Name   = "Private Coinbase Route Table"
  }
}

resource "aws_route_table" "public_subnet_route_table" {
  vpc_id = aws_vpc.coinbase_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.coinbase_igw.id
  }

  tags = {
    Name   = "Public Coinbase Route Table"
  }
}

resource "aws_main_route_table_association" "main_association" {
  vpc_id         = aws_vpc.coinbase_vpc.id
  route_table_id = aws_route_table.private_subnet_route_table.id
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.coinbase_subnet_a.id
  route_table_id = aws_route_table.public_subnet_route_table.id
}

resource "aws_security_group" "lambda_sg" {
  name        = "coinbase-lambda-sg"
  description = "Enable inbound and outbound traffic for the Coinbase Lambda function"
  vpc_id      = aws_vpc.coinbase_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.coinbase_vpc.cidr_block]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.coinbase_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "coinbase-lambda-sg"
  }
}

data "aws_iam_policy_document" "coinbase_lambda_policy_doc" {
  statement {
    sid     = "1"
    effect  = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ssm:GetParameter"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid     = "2"
    effect  = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
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

resource "aws_kms_key" "ssm_kms_key" {
  description             = "Coinbase KMS Key for encrypting SSM Parameters"
  tags = {
    Name = "Coinbase SSM KMS Key"
  }
}

resource "aws_kms_alias" "ssm_kms_key_alias" {
  name          = "alias/coinbase_ssm_kms_key"
  target_key_id = aws_kms_key.ssm_kms_key.key_id
}

data "aws_iam_policy_document" "coinbase_lambda_kms_policy_doc" {
  statement {
    sid     = "1"
    effect  = "Allow"
    actions = [
      "kms:DescribeKey",
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]
    resources = [
      "arn:aws:kms:${var.region}:${var.account_id}:key/${aws_kms_key.ssm_kms_key.key_id}"
    ]
  }
}

resource "aws_iam_policy" "coinbase_lambda_kms_policy" {
  name        = "coinbase-lambda-ssm-kms-key-policy"
  description = "The IAM policy for the Coinbase Lambda function to use the SSM KMS Key"
  policy      = data.aws_iam_policy_document.coinbase_lambda_kms_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "lambda-ssm-kms-policy-attachment" {
  role       = aws_iam_role.coinbase_lambda_role.name
  policy_arn = aws_iam_policy.coinbase_lambda_kms_policy.arn
}

resource "aws_lambda_function" "coinbase_lambda_deposit" {
  filename         = "python-scripts/lambda.zip"
  function_name    = "CoinbaseLambdaDeposit"
  role             = aws_iam_role.coinbase_lambda_role.arn
  handler          = "deposit-funds.lambda_handler"
  source_code_hash = filebase64sha256("python-scripts/lambda.zip")
  runtime          = "python3.8"
  timeout          = 10

  vpc_config {
    subnet_ids         = [aws_subnet.coinbase_subnet_b.id, aws_subnet.coinbase_subnet_c.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

resource "aws_lambda_function" "coinbase_lambda_order" {
  filename         = "python-scripts/lambda.zip"
  function_name    = "CoinbaseLambdaOrder"
  role             = aws_iam_role.coinbase_lambda_role.arn
  handler          = "order-crypto.lambda_handler"
  source_code_hash = filebase64sha256("python-scripts/lambda.zip")
  runtime          = "python3.8"
  timeout          = 10

  vpc_config {
    subnet_ids         = [aws_subnet.coinbase_subnet_b.id, aws_subnet.coinbase_subnet_c.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

resource "aws_cloudwatch_event_rule" "lambda_deposit_event_rule" {
  name                = "coinbase-lambda-deposit"
  description         = "Trigger CoinbaseLambdaDeposit on every Monday at 12am UTC"
  schedule_expression = var.deposit_cron_expression
}

resource "aws_cloudwatch_event_rule" "lambda_order_weekly_event_rule" {
  name                = "coinbase-lambda-weekly-order"
  description         = "Trigger CoinbaseLambdaOrder on every Monday at 12pm UTC"
  schedule_expression = var.weekly_cron_expression
}

resource "aws_cloudwatch_event_rule" "lambda_order_monthly_event_rule" {
  name                = "coinbase-lambda-monthly-order"
  description         = "Trigger CoinbaseLambdaOrder the first day of every month at 12am UTC"
  schedule_expression = var.monthly_cron_expression
}

resource "aws_cloudwatch_event_target" "lambda_deposit_event_target" {
  rule      = aws_cloudwatch_event_rule.lambda_deposit_event_rule.name
  target_id = "SendToDepositLambda"
  arn       = aws_lambda_function.coinbase_lambda_deposit.arn
  input     = "{\"deposit_amount\":\"${var.deposit_amount}\"}"
}

resource "aws_cloudwatch_event_target" "lambda_order_weekly_event_target" {
  for_each = var.weekly_product_orders
  rule      = aws_cloudwatch_event_rule.lambda_order_weekly_event_rule.name
  target_id = "SendToOrderLambdaWeekly${each.key}"
  arn       = aws_lambda_function.coinbase_lambda_order.arn
  input     = "{\"product_id\":\"${each.key}\", \"order_size\":${each.value}}"
}

resource "aws_cloudwatch_event_target" "lambda_order_monthly_event_target" {
  for_each = var.monthly_product_orders
  rule      = aws_cloudwatch_event_rule.lambda_order_monthly_event_rule.name
  target_id = "SendToOrderLambdaMonthly${each.key}"
  arn       = aws_lambda_function.coinbase_lambda_order.arn
  input     = "{\"product_id\":\"${each.key}\", \"order_size\":${each.value}}"
}

resource "aws_lambda_permission" "allow_cloudwatch_deposit_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.coinbase_lambda_deposit.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_deposit_event_rule.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_weekly_order_lambda" {
  statement_id  = "AllowExecutionFromWeeklyCloudWatchEventRule"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.coinbase_lambda_order.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_order_weekly_event_rule.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_monthly_order_lambda" {
  statement_id  = "AllowExecutionFromMonthlyCloudWatchEventRule"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.coinbase_lambda_order.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_order_monthly_event_rule.arn
}

resource "aws_sns_topic" "deposit_lambda_errors" {
  name = "DepositLambdaErrors"
}

resource "aws_sns_topic" "order_lambda_errors" {
  name = "OrderLambdaErrors"
}

resource "aws_sns_topic_subscription" "lambda_deposit_errors_sms_target" {
  count = var.sms_number_for_errors != "" ? 1 : 0
  topic_arn = aws_sns_topic.deposit_lambda_errors.arn
  protocol  = "sms"
  endpoint  = var.sms_number_for_errors
}

resource "aws_sns_topic_subscription" "lambda_order_errors_sms_target" {
  count = var.sms_number_for_errors != "" ? 1 : 0
  topic_arn = aws_sns_topic.order_lambda_errors.arn
  protocol  = "sms"
  endpoint  = var.sms_number_for_errors
}

resource "aws_cloudwatch_metric_alarm" "deposit_lambda_alarm" {
  alarm_name                = "DepositLambdaAlarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "Errors"
  namespace                 = "AWS/Lambda"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "This metric monitors any Errors thrown from the Coinbase deposit lambda function"
  dimensions = {
    "FunctionName" = "CoinbaseLambdaDeposit"
  }
  alarm_actions = [ aws_sns_topic.deposit_lambda_errors.arn ]
}

resource "aws_cloudwatch_metric_alarm" "order_lambda_alarm" {
  alarm_name                = "OrderLambdaAlarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "Errors"
  namespace                 = "AWS/Lambda"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "This metric monitors any Errors thrown from the Coinbase order lambda function"
  dimensions = {
    "FunctionName" = "CoinbaseLambdaOrder"
  }
  alarm_actions = [ aws_sns_topic.order_lambda_errors.arn ]
}
