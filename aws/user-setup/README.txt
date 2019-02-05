Terraform prints out IAM access key details (both the key and the secret) in plain text like following:
aws_iam_access_key.tf-user:
  id = AKIAJUMRKT7SINRXV2FQ
  secret = 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
  ses_smtp_password = AsmzTj4h748CB8GbC+cObmkZSpVO6mKNPUbeVT+pgpK3
  status = Active
  user = tf-user

Hence, the AWS API key & secret need to be created/extracted/stored by hand.
-> in order to create the terraform user here, you need a few IAM policies (which I haven't listed up anywhere).
