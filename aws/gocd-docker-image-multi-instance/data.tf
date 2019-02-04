data "template_file" "userdata-agent" {
  template = "${file("./agent-provisioning/userdata-agent.sh")}"
  vars = {
    server_ip = "${aws_instance.server.private_ip}"
  }
}

data "aws_kms_key" "terraform-key" {
  key_id = "arn:aws:kms:ap-southeast-1:910733575136:key/c0a08cab-2407-4e88-96dd-fda84c6c58a9"
}

data "aws_kms_key" "default-aws-key" {
  key_id = "arn:aws:kms:ap-southeast-1:910733575136:key/b39998f7-46ad-4860-9ce1-7c48c841d043"
}
