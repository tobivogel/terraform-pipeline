data "template_file" "dockerfile-agent" {
  template = "${file("./agent-config/Dockerfile.agent")}"
  vars = {
    server_ip = "${aws_instance.server.private_ip}"
  }
}
