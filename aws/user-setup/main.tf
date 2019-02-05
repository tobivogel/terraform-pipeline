# Create the AWS terraform user through terraform - as a precondition to any AWS related tf script
provider "aws" {
  region = "${var.region}"
}

# Create a terraform user
resource "aws_iam_user" "tf-user" {
  name = "tf-user"
  path = "/tools/terraform/"
}

resource "aws_iam_user_policy_attachment" "test-attach" {
  user       = "${aws_iam_user.tf-user.name}"
  policy_arn = "${data.aws_iam_policy.default-aws-ec2-full-access-policy.arn}"
}

resource "aws_iam_user_policy" "tf-user-iam-policy" {
  user = "${aws_iam_user.tf-user.name}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "iam:CreateInstanceProfile",
                "iam:DeleteInstanceProfile",
                "iam:GetRole",
                "iam:GetInstanceProfile",
                "iam:RemoveRoleFromInstanceProfile",
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:PutRolePolicy",
                "iam:AddRoleToInstanceProfile",
                "iam:CreatePolicy",
                "iam:ListInstanceProfilesForRole",
                "iam:PassRole",
                "iam:DeleteRolePolicy",
                "iam:GetRolePolicy"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}


resource "aws_key_pair" "auth" {
  key_name = "${var.key-name}"
  public_key = "${file(var.public-key-path)}"
}
