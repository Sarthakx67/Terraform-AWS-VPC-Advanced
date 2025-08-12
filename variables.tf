# foring user to provide value
variable "cidr_block" {
  
}
variable "env" {
  
}
# optional becuse we gave default values
variable "enable_dns_hostnames" {
  default = true
}
variable "enable_dns_support" {
  default = true
}
variable "project_name" {
  
}
variable "common_tags" {
  default = {}
}
variable "vpc_tags" {
  default = {}
}
variable "igw_tags" {
  default = {}
}
variable "public_subnet_cidr_block" {
  type = list
  validation { # validation is used to restrict amout of AZ's in this case
    condition = length(var.public_subnet_cidr_block) == 2
    error_message = "please provide 2 public subnet CIDR"
  }
}
variable "private_subnet_cidr_block" {
  type = list
  validation { # validation is used to restrict amout of AZ's in this case
    condition = length(var.private_subnet_cidr_block) == 2
    error_message = "please provide 2 private subnet CIDR"
  }
}
variable "database_subnet_cidr_block" {
  type = list
  validation { # validation is used to restrict amout of AZ's in this case
    condition = length(var.database_subnet_cidr_block) == 2
    error_message = "please provide 2 private subnet CIDR"
  }
}
variable "nat_gateway_tags" {
  default = {}
}
variable "public_route_table_tags" {
  default = {}
}
variable "private_route_table_tags" {
  default = {}
}
variable "database_route_table_tags" {
  default = {}
}
variable "db_subnet_group_tags" {
  default = {}
}
variable "is_peering_required" {
  default = false
}
variable "requestor_vpc_id" {
  
}
variable "default_route_table_id" {
  
}
variable "default_vpc_cidr" {
  
}