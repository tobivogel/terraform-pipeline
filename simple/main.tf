provider "aws" {
  region = "${var.region}"
}

resource "aws_key_pair" "auth" {
  key_name = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

resource "aws_security_group" "http-ssh-default" {

  #allow incoming http traffic
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #allow incoming ssh traffic
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #allow all outgoing traffic
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "simple-nginx" {
  ami = "${lookup(var.amis, var.region)}"
  instance_type = "t2.micro"

  security_groups = ["${aws_security_group.http-ssh-default.name}"]

  key_name = "${aws_key_pair.auth.key_name}"

  associate_public_ip_address = true

  user_data = "${file("./userdata.sh")}"

  tags {
    Name = "nginx"
  }
}
