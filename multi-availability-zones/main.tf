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
resource "aws_route" "public-internet-access" {
  route_table_id = "${aws_vpc.tools.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.tools-igw.id}"
}

# Create subnet (and map public IP straight away)
resource "aws_subnet" "tools-public" {
  count = "${length(var.availability-zones)}"
  availability_zone = "${element(var.availability-zones, count.index)}"
  cidr_block = "10.0.${count.index}.0/24"
  vpc_id = "${aws_vpc.tools.id}"
  map_public_ip_on_launch = true

  tags {
    Name = "tools-public"
  }
}

# Default security group to access the EC2 instances
resource "aws_security_group" "public-sg" {
  name = "public-sg"
  description = "open up internet facing http/ssh ports for instances"
  vpc_id = "${aws_vpc.tools.id}"

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

  tags {
    Name = "public-sg"
  }
}

# Default security group to access the EC2 instances
resource "aws_security_group" "private-sg" {
  name = "private-sg"
  description = "only allow traffic from/to public-sg"
  vpc_id = "${aws_vpc.tools.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "private-sg"
  }
}

//resource "aws_elb" "web-elb" {
//  name = "public-elb"
//
//  subnets         = ["${aws_subnet.tools-public.*.id}"]
//  security_groups = ["${aws_security_group.public-sg.id}"]
//  instances       = ["${aws_instance.nginx.*.id}"]
//  availability_zones = ["${var.availability-zones}"]
//
//  listener {
//    instance_port     = 80
//    instance_protocol = "http"
//    lb_port           = 80
//    lb_protocol       = "http"
//  }
//}

resource "aws_lb" "web-alb" {
  name = "public-alb"
  load_balancer_type = "application"

  subnets = ["${aws_subnet.tools-public.*.id}"]
  security_groups = ["${aws_security_group.public-sg.id}"]
}

resource "aws_lb_listener" "http-listener" {
  load_balancer_arn = "${aws_lb.web-alb.arn}"
  port = 80
  protocol = "HTTP"

  "default_action" {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.web-target-group.arn}"
  }
}

resource "aws_lb_target_group" "web-target-group" {
  name = "web-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = "${aws_vpc.tools.id}"
}

resource "aws_lb_target_group_attachment" "web-target-group-instances" {
  target_group_arn = "${aws_lb_target_group.web-target-group.arn}"
  target_id        = "${element(aws_instance.nginx.*.id, count.index)}"
  port             = 80
  count = "${length(var.availability-zones)}"
}

resource "aws_key_pair" "auth" {
  key_name = "${var.key-name}"
  public_key = "${file(var.public-key-path)}"
}

resource "aws_instance" "nginx" {
  ami = "${lookup(var.amis, var.region)}"
  instance_type = "t2.nano"
  count = "${length(var.availability-zones)}"
  availability_zone = "${element(var.availability-zones, count.index)}"

  subnet_id = "${element(aws_subnet.tools-public.*.id, count.index)}"

  vpc_security_group_ids = ["${aws_security_group.private-sg.id}"]

  key_name = "${aws_key_pair.auth.id}"

  user_data = "${file(var.userdata-path)}"

  connection {
    user = "ec2-user"
  }

  provisioner "file" {
    content     = <<CONTENT
infos:
- ami used: ${self.ami}
- id: ${self.id}
- availability zone: ${self.availability_zone}
- subnet: ${self.subnet_id}
CONTENT
    destination = "/tmp/instance-info.yaml"
  }

  provisioner "file" {
    source = "${var.static-page-path}"
    destination = "/tmp/index.html"
  }
}
