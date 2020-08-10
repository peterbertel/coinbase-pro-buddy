output "elastic_ip_address" {
  value = aws_eip.nat.public_ip
}