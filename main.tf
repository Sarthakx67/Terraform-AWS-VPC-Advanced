# creating main vpc for roboshop project
resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support = var.enable_dns_support

  tags = merge(
    var.common_tags,
    {
        Name = var.project_name
    },
    {
      vpc_tags = var.vpc_tags
    }
  )
}
# creating internet gateway for roboshop project vpc
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      igw_tags = var.igw_tags
    },
    {
        Name = var.project_name
    }
  )
}
# creating aws public subnet in roboshop vpc
resource "aws_subnet" "public_subnet" {
  count = length(var.public_subnet_cidr_block)
    map_public_ip_on_launch = true
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr_block[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-public-${local.azs[count.index]}"
    }
  )
}
# creating aws private subnet in roboshop vpc
resource "aws_subnet" "private_subnet" {
  count = length(var.private_subnet_cidr_block)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr_block[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-private-${local.azs[count.index]}"
    }
  )
}
# creating aws database subnet in roboshop vpc
resource "aws_subnet" "database_subnet" {
  count = length(var.database_subnet_cidr_block)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.database_subnet_cidr_block[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-database-${local.azs[count.index]}"
    }
  )
}
# creating public route table for roboshop vpc 
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  # route {
  #   cidr_block = "0.0.0.0/0"
  #   gateway_id = aws_internet_gateway.igw.id
  # }

# routes should be always added seprately as it conflics with terraform resource creation

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-public_rt"
    },
    var.public_route_table_tags
  )
}
# adding internet gateway inside public route table using "aws_route" seprately
resource "aws_route" "public_route" {
  route_table_id = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}
# creating elastic ip for nat gateway  
resource "aws_eip" "elastic_ip" {
  domain   = "vpc"
}

#===========================TESTING-START======================================================

# creating nat gateway
# resource "aws_nat_gateway" "nat_gateway" {
#   allocation_id = aws_eip.elastic_ip.id
#   subnet_id     = aws_subnet.public_subnet[0].id # we are giving 0 as we have 2 subnets so it will be provisioned to ap-south-1a if we give 1 it will connect to ap-south-1b

#   tags = merge(
#     var.common_tags,
#     {
#         Name = var.project_name
#     },
#     var.nat_gateway_tags
#   )
#   # To ensure proper ordering, it is recommended to add an explicit dependency
#   # on the Internet Gateway for the VPC.
#   depends_on = [aws_internet_gateway.igw]
# }

#===========================TESTING-END======================================================

# creating private route table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  # in public route table we were connect through internet gateway but in private route table
  # we will be connecting through nat gateway to internet 
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-private_rt"
    },
    var.private_route_table_tags
  )
}

# ========================TESTING-START=====================================================

# # routing nat gateway to private route table
# resource "aws_route" "private_route" {
#   route_table_id            = aws_route_table.private_rt.id
#   destination_cidr_block    = "0.0.0.0/0"
#   nat_gateway_id = aws_nat_gateway.nat_gateway.id
# }

# # routing INTERNET gateway to private route table FOR TESTING
resource "aws_route" "private_route" {
  route_table_id            = aws_route_table.private_rt.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}


# ========================TESTING-END=====================================================

# creating database route table 
resource "aws_route_table" "database_rt" {
  vpc_id = aws_vpc.main.id

  # in public route table we were connect through internet gateway but in private route table
  # we will be connecting through nat gateway to internet 

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-database_rt"
    },
    var.database_route_table_tags
  )
}

# ========================TESTING-START=====================================================

# # routing nat gateway to database route table
# resource "aws_route" "database_route" {
#   route_table_id            = aws_route_table.database_rt.id
#   destination_cidr_block    = "0.0.0.0/0"
#   nat_gateway_id = aws_nat_gateway.nat_gateway.id
# }

# # routing nat gateway to database route table
resource "aws_route" "database_route" {
  route_table_id            = aws_route_table.database_rt.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

# ========================TESTING-END=====================================================


# establishing association between public_route_table with public_subnet
resource "aws_route_table_association" "public_subnet_association" {
  count = length(var.public_subnet_cidr_block)
  subnet_id = element(aws_subnet.public_subnet[*].id, count.index)

#  fucntion --> element(aws_subnet.public_subnet[*].id, count.index)
#  above function will fetch list of subnets which are "public-subnet-1" and "public-subnet-2"
#  out of which "count.index" will select all list and perform action

  route_table_id = aws_route_table.public_rt.id
}
# establishing association between private_route_table with private_subnet
resource "aws_route_table_association" "private_subnet_association" {
  count = length(var.private_subnet_cidr_block)
  subnet_id = element(aws_subnet.private_subnet[*].id, count.index)
  route_table_id = aws_route_table.private_rt.id
}
# establishing association between database_route_table with database_subnet
resource "aws_route_table_association" "database_subnet_association" {
  count = length(var.database_subnet_cidr_block)
  subnet_id = element(aws_subnet.database_subnet[*].id, count.index)
  route_table_id = aws_route_table.database_rt.id
}

# we are just creating database subnet groups
resource "aws_db_subnet_group" "roboshop-database" {
  name       = "${var.project_name}-${var.env}"
  subnet_ids = aws_subnet.database_subnet[*].id

  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-${var.env}"
    },
    var.db_subnet_group_tags
  )
}