provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_instance" "example" {
  ami = "ami-16a4fe6a"
#  ami = "ami-8e0205f2"
  instance_type = "t2.micro"
}
