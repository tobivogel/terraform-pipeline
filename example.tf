provider "aws" {
  region = "${var.region}"
}

resource "aws_instance" "example" {
  ami = "${lookup(var.amis, var.region)}"
  instance_type = "t2.micro"
}

resource "aws_eip" "ip" {
  instance = "${aws_instance.example.id}"
}

variable "region" {
  default = "ap-southeast-1"
}

variable "amis" {
  type = "map"
  default = {
    "ap-southeast-1" = "ami-8e0205f2",
    "ap-southeast-2" = "ami-d8c21dba"
  }
}

output "ami" {
  value = "${lookup(var.amis, var.region)}"
}

output "ip-address" {
  value = "${aws_eip.ip.public_ip}"
}
