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

variable "public-key-path" {
  description = <<DESCRIPTION
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.
Example: ~/.ssh/terraform.pub
DESCRIPTION
  default = "~/.ssh/terraform.key.pub"
}

variable "key-name" {
  description = "Desired name of AWS key pair"
  default = "terraform.key"
}

variable "userdata-path" {
  description = "Shell script executed after provisioning the EC2 instance"
  default = "./../scripts/userdata.sh"
}
