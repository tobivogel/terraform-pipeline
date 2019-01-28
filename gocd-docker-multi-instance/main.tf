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
resource "aws_route" "www-access" {
  route_table_id = "${aws_vpc.tools.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.tools-igw.id}"
}

# Create subnet (and map public IP straight away)
resource "aws_subnet" "tools-public-ip" {
  cidr_block = "10.0.0.0/24"
  vpc_id = "${aws_vpc.tools.id}"
  map_public_ip_on_launch = true
}


resource "aws_security_group" "server-sg" {
  vpc_id = "${aws_vpc.tools.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # assumption that the server needs this to download binaries
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # GoCD needs this for HTTP connections
  ingress {
    from_port = 8153
    to_port = 8153
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # GoCD needs this for HTTPS connections
  ingress {
    from_port = 8154
    to_port = 8154
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "agent-sg" {
  vpc_id = "${aws_vpc.tools.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # assumption that the server needs this to download binaries
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8154
    to_port = 8154
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

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

resource "aws_instance" "server" {
  ami = "${lookup(var.amis, var.region)}"
  instance_type = "t2.micro"

  subnet_id = "${aws_subnet.tools-public-ip.id}"
  vpc_security_group_ids = ["${aws_security_group.server-sg.id}"]

  key_name = "${aws_key_pair.auth.id}"

  user_data = "${file(var.server-user-data-path)}"

  connection {
    user = "ec2-user"
  }

  provisioner "file" {
    source = "${var.server-config-path}"
    destination = "~"
  }

  tags {
    Name = "server"
  }
}

resource "local_file" "save-docker-agent-with-ip" {
  content = "${data.template_file.dockerfile-agent.rendered}"
  filename = "${"./agent-config/Dockerfile.agent"}"
}

resource "aws_instance" "agent" {
  ami = "${lookup(var.amis, var.region)}"
  instance_type = "t2.micro"

  subnet_id = "${aws_subnet.tools-public-ip.id}"
  vpc_security_group_ids = ["${aws_security_group.agent-sg.id}"]

  key_name = "${aws_key_pair.auth.id}"

  user_data = "${file(var.agent-user-data-path)}"

  depends_on = ["local_file.save-docker-agent-with-ip"]

  connection {
    user = "ec2-user"
  }

  provisioner "file" {
    source = "${var.agent-config-path}"
    destination = "~"
  }

  tags {
    Name = "agent"
  }
}
