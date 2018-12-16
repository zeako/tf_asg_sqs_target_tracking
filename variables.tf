variable "ec2_instance_type" {}

variable "provisioner" {
  default = "Terraform"
}

variable "region" {
  default = "us-east-1"
}

variable "resource_prefix" {
  default = ""
}

variable "vpc_cidr_block" {}
