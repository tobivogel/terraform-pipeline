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
  count = "${length(var.availability-zones)}"
  availability_zone = "${element(var.availability-zones, count.index)}"
  cidr_block = "10.0.${count.index}.0/24"
  vpc_id = "${aws_vpc.tools.id}"
  map_public_ip_on_launch = true
}

# HTTP ingress from everywhere
resource "aws_security_group" "public-lb-sg" {
  name = "public-lb-sg"
  description = "open up internet facing http ports"
  vpc_id = "${aws_vpc.tools.id}"

  # HTTP/HTTPS access (over the GoCD exposed ports) from VPC
  # this needs to include the Public IP of the instance
  # might need more ports depending on how dependencies get pulled down
  ingress {
    from_port = 8153
    to_port = 8153
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 8154
    to_port = 8154
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  # TODO: restrict to ports actually needed
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SSH ingress from everywhere, HTTP only VPC internally
# Might need some tweaking/splitting to open up gocd agent/server communication & agent (and potentially server) internet access
resource "aws_security_group" "private-sg" {
  name = "private-sg"
  description = "only allow traffic from/to public-sg"
  vpc_id = "${aws_vpc.tools.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # assumption that the go agent needs this to download binaries
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8153
    to_port = 8153
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
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

resource "aws_lb" "web-alb" {
  name = "public-alb"
  load_balancer_type = "application"

  subnets = ["${aws_subnet.tools-public-ip.*.id}"]
  security_groups = ["${aws_security_group.public-lb-sg.id}"]
}

resource "aws_lb_listener" "http-listener" {
  load_balancer_arn = "${aws_lb.web-alb.arn}"
  port = 8153
  protocol = "HTTP"

  "default_action" {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.http-target-group.arn}"
  }
}

resource "aws_lb_target_group" "http-target-group" {
  name = "http-target-group"
  port = 8153
  protocol = "HTTP"
  vpc_id = "${aws_vpc.tools.id}"
}

resource "aws_lb_target_group_attachment" "http-target-group-instances" {
  target_group_arn = "${aws_lb_target_group.http-target-group.arn}"
  target_id        = "${aws_instance.server.id}"
  port             = 8153
}

//resource "aws_lb_listener" "https-listener" {
//  load_balancer_arn = "${aws_lb.web-alb.arn}"
//  port = 8154
//  protocol = "HTTPS"
//
//  "default_action" {
//    type = "forward"
//    target_group_arn = "${aws_lb_target_group.https-target-group.arn}"
//  }
//}

//resource "aws_lb_target_group" "https-target-group" {
//  name = "https-target-group"
//  port = 8154
//  protocol = "HTTPS"
//  vpc_id = "${aws_vpc.tools.id}"
//}

//resource "aws_lb_target_group_attachment" "https-target-group-instances" {
//  target_group_arn = "${aws_lb_target_group.https-target-group.arn}"
//  target_id        = "${aws_instance.server.id}"
//  port             = 8154
//}

resource "aws_key_pair" "auth" {
  key_name = "${var.key-name}"
  public_key = "${file(var.public-key-path)}"
}

resource "aws_instance" "server" {
  ami = "${lookup(var.amis, var.region)}"
  instance_type = "t2.micro"

  subnet_id = "${element(aws_subnet.tools-public-ip.*.id, count.index)}"

  vpc_security_group_ids = ["${aws_security_group.private-sg.id}"]

  key_name = "${aws_key_pair.auth.id}"

  user_data = "${file(var.server-userdata-path)}"

  connection {
    user = "ec2-user"
  }

  # provide docker files from S3 or a VCS to make it machine independent
  provisioner "file" {
    source = "${var.docker-config-path}"
    destination = "~"
  }
}
