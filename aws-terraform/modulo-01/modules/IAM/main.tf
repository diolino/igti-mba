
resource "aws_iam_policy" "s3_full_access_policy" {
  name        = "s3_full_access_policy"
  path        = "/"
  description = "My test policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*",
                "s3-object-lambda:*"
            ],
            "Resource": "*"
        }
    ]
})
}

resource "aws_iam_role" "ec2_s3manager_role" {
  name = "ec2_s3manager_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Project = "gtdiolino.lab"    
  }
}

resource "aws_iam_role_policy_attachment" "ec2role_s3policy_attach" {
  role       = aws_iam_role.ec2_s3manager_role.name
  policy_arn = aws_iam_policy.s3_full_access_policy.arn
}

resource "aws_iam_instance_profile" "ec2_semanager_profile" {
  name = "ec2_semanager_profile"
  role = aws_iam_role.ec2_s3manager_role.name
}