output "elastic_ip_address" {
  value = aws_eip.nat.public_ip
}

output "vpc" {
  value = aws_vpc.coinbase_vpc.id
}

output "nat_gateway" {
  value = aws_nat_gateway.gateway.id
}

output "lambda_function" {
  value = aws_lambda_function.coinbase_lambda.arn
}
