output "elastic_ip_address" {
  value = aws_eip.nat.public_ip
}

output "vpc" {
  value = aws_vpc.coinbase_vpc.id
}

output "igw" {
  value = aws_internet_gateway.coinbase_igw.id
}

output "subnet_a" {
  value = aws_subnet.coinbase_subnet_a.id
}

output "subnet_b" {
  value = aws_subnet.coinbase_subnet_b.id
}

output "subnet_c" {
  value = aws_subnet.coinbase_subnet_c.id
}

output "nat_gateway" {
  value = aws_nat_gateway.gateway.id
}

output "security_group" {
  value = aws_security_group.lambda_sg.id
}

output "lambda_deposit" {
  value = aws_lambda_function.coinbase_lambda_deposit.arn
}

output "lambda_order" {
  value = aws_lambda_function.coinbase_lambda_order.arn
}
