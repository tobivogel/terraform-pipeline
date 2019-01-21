output "public-dns" {
  value = "${aws_elb.web-elb.dns_name}"
}

output "nginx-instance-id" {
  value = "${aws_instance.nginx.id}"
}

output "nginx-public-ip" {
  value = "${aws_instance.nginx.public_ip}"
}
