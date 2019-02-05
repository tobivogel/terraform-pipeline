data "aws_kms_key" "default-aws-key" {
  key_id = "arn:aws:kms:ap-southeast-1:910733575136:key/b39998f7-46ad-4860-9ce1-7c48c841d043"
}

data "aws_iam_policy" "default-aws-ec2-full-access-policy" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}
