provider "aws" {
  region = "${var.region}"
}

variable "region" {
  default = "ap-southeast-1"
}

module "tools" {
  source  = "simple-no-default"
//  agents = 1
}

output "ip-address" {
  value = "${module.tools.public-ip}"
}
