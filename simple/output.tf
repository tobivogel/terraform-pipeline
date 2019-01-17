output "ip-address" {
  value = "${aws_instance.simple-nginx.public_ip}"
}
