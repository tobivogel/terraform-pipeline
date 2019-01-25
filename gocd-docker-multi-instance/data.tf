data "template_file" "dockerfile-agent" {
  template = "${file("./docker/Dockerfile.agent")}"
  vars = {
    server_ip = "${aws_instance.server.private_ip}"
  }
}

data "template_file" "dockerfile-server" {
  template = "${file("./docker/Dockerfile.server")}"
}
