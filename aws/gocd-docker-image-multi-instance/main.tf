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

  egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # needed to download dependencies (would not be needed if they would already be baked into an image)
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 443
    to_port = 443
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

  egress {
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
    from_port = 8154
    to_port = 8154
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
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

  egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # needed to download dependencies (would not be needed if they would already be baked into an image)
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # GoCD agents connect to the server over HTTPS on 8154
  ingress {
    from_port = 8154
    to_port = 8154
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port = 8154
    to_port = 8154
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

# Create an IAM role for the GoCD Server in order to read keys from KMS.
resource "aws_iam_role" "server_iam_role" {
  name = "server_iam_role"
  assume_role_policy = "${data.aws_iam_policy_document.server_instance.json}"
}

data "aws_iam_policy_document" "server_instance" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_instance_profile" "server_instance_profile" {
  name = "server_instance_profile"
  role = "server_iam_role"
}

resource "aws_iam_role_policy" "server_iam_role_policy" {
  name = "server_use_kms_iam_role_policy"
  role = "${aws_iam_role.server_iam_role.id}"
  policy = "${data.aws_iam_policy_document.server_permissions.json}"
}

data "aws_iam_policy_document" "server_permissions" {
  statement {
    effect = "Allow"
    resources = ["*"]
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
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

  tags {
    Name = "server"
  }
}

resource "aws_instance" "agent" {
  ami = "${lookup(var.amis, var.region)}"
  instance_type = "t2.micro"

  subnet_id = "${aws_subnet.tools-public-ip.id}"
  vpc_security_group_ids = ["${aws_security_group.agent-sg.id}"]

  key_name = "${aws_key_pair.auth.id}"

  user_data = "${data.template_file.userdata-agent.rendered}"

  iam_instance_profile = "${aws_iam_instance_profile.server_instance_profile.id}"

  connection {
    user = "ec2-user"
  }

  provisioner "file" {
    source = "${var.agent-credentials-path}"
    destination = "~/"
  }

  tags {
    Name = "agent"
  }
}
