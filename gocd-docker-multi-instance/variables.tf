variable "region" {
  default = "ap-southeast-1"
}

variable "amis" {
  type = "map"
  default = {
    "ap-southeast-1" = "ami-04677bdaa3c2b6e24"
  }
}

// ECS optimised amazon-linux-2 AMI
//"ap-southeast-1" = "ami-06227143764cbe5b6",
//"ap-southeast-2" = "ami-03ba7b79573cdbe5e"
//
// Plain amazon-linux-2 AMI
//"ap-southeast-1" = "ami-04677bdaa3c2b6e24"

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

variable "agent-user-data-path" {
  description = "path to agent config files"
  default = "./agent-config/userdata-agent.sh"
}

variable "agent-config-path" {
  description = "path to agent config files"
  default = "./agent-config/"
}

variable "server-user-data-path" {
  description = "Path to server config files"
  default = "./server-config/userdata-server.sh"
}

variable "server-config-path" {
  description = "Path to server config files"
  default = "./server-config/"
}
