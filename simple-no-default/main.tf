# Checkout https://blog.codeship.com/terraforming-your-docker-environment-on-aws/ for some inspiration

provider "aws" {
  region = "${var.region}"
}

resource "aws_vpc" "tools" {
  cidr_block = "10.0.0.0/16"
}

# VPC to create bridge between subnets and outside world
resource "aws_internet_gateway" "tools-igw" {
  vpc_id = "${aws_vpc.tools.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet-access" {
  route_table_id = "${aws_vpc.tools.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.tools-igw.id}"
}

# Create subnet (and map public IP straight away)
resource "aws_subnet" "tools-public" {
  cidr_block = "10.0.0.0/24"
  vpc_id = "${aws_vpc.tools.id}"
  map_public_ip_on_launch = true
}

# Default security group to access the EC2 instances
resource "aws_security_group" "default-http" {
  name = "default-http-sg"
  description = "open up internet facing http ports for instances"
  vpc_id = "${aws_vpc.tools.id}"

  # SSH access from anywhere (needed for (remote exec) provisioner
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from VPC
  # this needs to include the Public IP of the instance
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "auth" {
  key_name = "${var.key-name}"
  public_key = "${file(var.public-key-path)}"
}

resource "aws_instance" "nginx" {
  ami = "${lookup(var.amis, var.region)}"
  instance_type = "t2.micro"

  # We're going to launch into the same subnet as our ELB. In a production
  # environment it's more common to have a separate private subnet for
  # backend instances.
  subnet_id = "${aws_subnet.tools-public.id}"

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.default-http.id}"]

  # Name of the keypair used
  key_name = "${aws_key_pair.auth.id}"

  # We run a remote provisioner on the instance after creating it.
  # In this case, we just install nginx and start it. By default,
  # this should be on port 80
  user_data = "${file(var.userdata-path)}"
}
