# creating main vpc for roboshop project
resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support = var.enable_dns_support

  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-${var.env}"
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
        Name = "${var.project_name}-${var.env}"
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
        Name = "${var.project_name}-${var.env}-public-${local.azs[count.index]}"
    }
  )
}

# creating aws private subnet in roboshop vpc
resource "aws_subnet" "private_subnet" {
  count = length(var.private_subnet_cidr_block)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr_block[count.index]
  availability_zone = local.azs[count.index]

  # ========== TESTING MODE: IGW ==========
  # Enable public IP for private subnets when using IGW
  map_public_ip_on_launch = true
  # =======================================

  # ========== PRODUCTION MODE: NAT ==========
  # Comment above line when using NAT Gateway
  # map_public_ip_on_launch = false
  # ==========================================

  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-${var.env}-private-${local.azs[count.index]}"
    }
  )
}

# creating aws database subnet in roboshop vpc
resource "aws_subnet" "database_subnet" {
  count = length(var.database_subnet_cidr_block)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.database_subnet_cidr_block[count.index]
  availability_zone = local.azs[count.index]

  # ========== TESTING MODE: IGW ==========
  # Enable public IP for database subnets when using IGW
  map_public_ip_on_launch = true
  # =======================================

  # ========== PRODUCTION MODE: NAT ==========
  # Comment above line when using NAT Gateway
  # map_public_ip_on_launch = false
  # ==========================================

  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-${var.env}-database-${local.azs[count.index]}"
    }
  )
}

# creating public route table for roboshop vpc 
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.env}-public_rt"
    },
    var.public_route_table_tags
  )
}

# adding internet gateway inside public route table
resource "aws_route" "public_route" {
  route_table_id = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

# creating elastic ip for nat gateway  
resource "aws_eip" "elastic_ip" {
  domain   = "vpc"
}

# ========== PRODUCTION MODE: NAT GATEWAY ==========
# Uncomment below block when switching to NAT Gateway
# resource "aws_nat_gateway" "nat_gateway" {
#   allocation_id = aws_eip.elastic_ip.id
#   subnet_id     = aws_subnet.public_subnet[0].id
#
#   tags = merge(
#     var.common_tags,
#     {
#         Name = "${var.project_name}-${var.env}"
#     },
#     var.nat_gateway_tags
#   )
#
#   depends_on = [aws_internet_gateway.igw]
# }
# ==================================================

# creating private route table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.env}-private_rt"
    },
    var.private_route_table_tags
  )
}

# ========== TESTING MODE: IGW ==========
# Private subnet routes through IGW (for testing only)
resource "aws_route" "private_route" {
  route_table_id            = aws_route_table.private_rt.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}
# =======================================

# ========== PRODUCTION MODE: NAT ==========
# Uncomment below and comment above when using NAT Gateway
# resource "aws_route" "private_route" {
#   route_table_id            = aws_route_table.private_rt.id
#   destination_cidr_block    = "0.0.0.0/0"
#   nat_gateway_id = aws_nat_gateway.nat_gateway.id
# }
# ==========================================

# creating database route table 
resource "aws_route_table" "database_rt" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.env}-database_rt"
    },
    var.database_route_table_tags
  )
}

# ========== TESTING MODE: IGW ==========
# Database subnet routes through IGW (for testing only)
resource "aws_route" "database_route" {
  route_table_id            = aws_route_table.database_rt.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}
# =======================================

# ========== PRODUCTION MODE: NAT ==========
# Uncomment below and comment above when using NAT Gateway
# resource "aws_route" "database_route" {
#   route_table_id            = aws_route_table.database_rt.id
#   destination_cidr_block    = "0.0.0.0/0"
#   nat_gateway_id = aws_nat_gateway.nat_gateway.id
# }
# ==========================================

# establishing association between public_route_table with public_subnet
resource "aws_route_table_association" "public_subnet_association" {
  count = length(var.public_subnet_cidr_block)
  subnet_id = element(aws_subnet.public_subnet[*].id, count.index)
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