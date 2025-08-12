# this local is used to find out all availability zones
# local is used for this task as it cant get overwrite
# then slice fucntion is used to get only 2 AZ-s

locals {
  azs = slice(data.aws_availability_zones.available.names,0,2)
}
# output "azs" {
#   value = local.azs
# }