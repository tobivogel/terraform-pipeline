output "public-dns" {
  value = "${aws_lb.web-alb.dns_name}"
}

output "server-instance-id" {
  value = "${aws_instance.server.id}"
}

output "server-public-ip" {
  value = "${aws_instance.server.public_ip}"
}
