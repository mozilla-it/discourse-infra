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

output "iam_role_arn" {
  value       = "${aws_iam_role.discourse_role.arn}"
  description = "Discourse role ARN"
}
