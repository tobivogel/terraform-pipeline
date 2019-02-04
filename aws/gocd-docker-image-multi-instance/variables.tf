variable "region" {
  default = "ap-southeast-1"
}

variable "amis" {
  type = "map"
  default = {
    "ap-southeast-1" = "ami-04677bdaa3c2b6e24"
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

variable "docker-login-cred-key" {
  description = "Wrapped AWS Data Key - wrapped with data.aws_kms_key.terraform-key"
  default = ""
}

variable "docker-login-cred-pass" {
  description = "Encrypted docker login"
  default = ""
}

variable "agent-user-data-path" {
  description = "path to agent config files"
  default = "./agent-provisioning/userdata-agent.sh"
}

variable "agent-credentials-path" {
  description = "path to agent credentials files"
  default = "./agent-provisioning/credentials/"
}

variable "server-user-data-path" {
  description = "Path to server config files"
  default = "./server-provisioning/userdata-server.sh"
}
