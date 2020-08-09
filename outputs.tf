output "elastic_ip_address" {
  value = aws_eip.elastic_ip_address.public_ip
}