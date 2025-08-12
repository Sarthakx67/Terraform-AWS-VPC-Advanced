output "vpc_id" {
  value = aws_vpc.main.id # this is the output module developer is providing
}
output "public_subnet_ids" {
  value = aws_subnet.public_subnet[*].id
}
output "private_subnet_ids" {
  value = aws_subnet.private_subnet[*].id
}
output "database_subnet_ids" {
  value = aws_subnet.database_subnet[*].id
}