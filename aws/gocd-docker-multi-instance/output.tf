output "server-instance-id" {
  value = "${aws_instance.server.id}"
}

output "server-public-ip" {
  value = "${aws_instance.server.public_ip}"
}

output "server-private-ip" {
  value = "${aws_instance.server.private_ip}"
}

output "agent-instance-id" {
  value = "${aws_instance.agent.id}"
}

output "agent-public-ip" {
  value = "${aws_instance.agent.public_ip}"
}

output "agent-private-ip" {
  value = "${aws_instance.agent.private_ip}"
}
