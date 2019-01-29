output "public-ip" {
  value = "${aws_instance.nginx.public_ip}"
}

output "nginx-instance-id" {
  value = "${aws_instance.nginx.id}"
}
