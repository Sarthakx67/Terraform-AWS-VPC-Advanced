# vpc peering with default vpc
resource "aws_vpc_peering_connection" "peering" {
  count = var.is_peering_required ? 1 : 0
  #peer_owner_id = var.peer_owner_id
  peer_vpc_id   = aws_vpc.main.id
  #requestor, default VPC is our requestor
  vpc_id        = var.requestor_vpc_id
  auto_accept   = true

  tags = merge(
    {
      Name = "${var.project_name}-${var.env}"
    },
    var.common_tags
  )
}
# adding vpc peering route for default vpc
resource "aws_route" "default_route" {
  count = var.is_peering_required ? 1 : 0
  route_table_id            = var.default_route_table_id # Providing Default VPC route table id
  destination_cidr_block    = var.cidr_block # providing our roboshop vpc cidr block as destination for peering
  # since we set count parameter, it is treated as list, even single element you should write list syntax
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
  #depends_on                = [aws_route_table.testing]
}
# adding vpc peering route for public subnet in roboshop vpc
resource "aws_route" "public_peering" {
  count = var.is_peering_required ? 1 : 0
  route_table_id            = aws_route_table.public_rt.id
  destination_cidr_block    = var.default_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
  #depends_on                = [aws_route_table.testing]
}
# adding vpc peering route for private subnet in roboshop vpc
resource "aws_route" "private_peering" {
  count = var.is_peering_required ? 1 : 0
  route_table_id            = aws_route_table.private_rt.id
  destination_cidr_block    = var.default_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
  #depends_on                = [aws_route_table.testing]
}
# adding vpc peering route for database subnet in roboshop vpc
resource "aws_route" "database_peering" {
  count = var.is_peering_required ? 1 : 0
  route_table_id            = aws_route_table.database_rt.id
  destination_cidr_block    = var.default_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
  #depends_on                = [aws_route_table.testing]
}
