output "elastic_ip_address" {
  value = aws_eip.nat.public_ip
}

output "nat_gateway" {
  value = aws_nat_gateway.gateway.id
}
