resource "aws_iam_role" "discourse_role" {
  name               = "discourse-${terraform.workspace}"
  path               = "/discourse/"
  assume_role_policy = "${data.aws_iam_policy_document.allow_assume_role.json}"
}

data "aws_iam_policy_document" "allow_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }

  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/k8s-apps-prod-us-west-220190606230725142700000003"]
    }
  }
}

resource "aws_iam_role_policy" "discourse" {
  name = "discourse-${terraform.workspace}"
  role = "${aws_iam_role.discourse_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.uploads.arn}/*",
        "${aws_s3_bucket.uploads.arn}"
			]
    }
  ]
}
EOF
}

output "iam_role_arn" {
  value       = "${aws_iam_role.discourse_role.arn}"
  description = "Discourse role ARN"
}

resource "aws_iam_role" "telegraf" {
  name               = "telegraf-${terraform.workspace}"
  path               = "/discourse/"
  assume_role_policy = "${data.aws_iam_policy_document.allow_assume_role.json}"
}

resource "aws_iam_role_policy" "telegraf" {
  name = "telegraf-discourse-${terraform.workspace}"
  role = "${aws_iam_role.telegraf.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cloudwatch:Describe*",
        "cloudwatch:Get*",
        "cloudwatch:List*"
      ],
      "Effect": "Allow",
      "Resource": [ "*" ]
    }
  ]
}
EOF
}
