data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  az_count = "${length(data.aws_availability_zones.available.names)}"
}
