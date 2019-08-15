resource "aws_iam_user" "lmcardle" {
  name = "lmcardle"

  # Not supported by EKS:
  #path = "/discourse/"
  tags = "${merge(var.common-tags, var.workspace-tags)}"
}

resource "aws_iam_user_login_profile" "lmcardle" {
  user    = "${aws_iam_user.lmcardle.name}"
  pgp_key = "keybase:leomca"
}

output "password" {
  value = "${aws_iam_user_login_profile.lmcardle.encrypted_password}"
}

resource "aws_iam_group" "developers" {
  name = "developers"
  path = "/discourse/"
}

resource "aws_iam_group_membership" "devs" {
  name  = "discourse-developer"
  users = ["${aws_iam_user.lmcardle.name}"]
  group = "${aws_iam_group.developers.name}"
}

resource "aws_iam_group_policy" "discourse-devs" {
  name  = "discourse-developer-policy"
  group = "${aws_iam_group.developers.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters"
      ],
      "Effect": "Allow",
      "Resource": "*",
    },
    {
      "Action": [
        "codebuild:*",
      ],
      "Effect": "Allow",
      "Resource": "*",
			"Condition" : {
        "StringEquals" : {
          "aws:ResourceTag/project-name" : "discourse"
        }
			}
    }
  ]
}
EOF
}

resource "aws_iam_group_policy" "self-managed-mfa" {
  name  = "self-managed-mfa"
  group = "${aws_iam_group.developers.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowListActions",
            "Effect": "Allow",
            "Action": [
                "iam:ListUsers",
                "iam:ListVirtualMFADevices"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowIndividualUserToListOnlyTheirOwnMFA",
            "Effect": "Allow",
            "Action": [
                "iam:ListMFADevices"
            ],
            "Resource": [
                "arn:aws:iam::*:mfa/*",
                "arn:aws:iam::*:user/${aws_iam_user.lmcardle.name}"
            ]
        },
        {
            "Sid": "AllowIndividualUserToManageTheirOwnMFA",
            "Effect": "Allow",
            "Action": [
                "iam:CreateVirtualMFADevice",
                "iam:DeleteVirtualMFADevice",
                "iam:EnableMFADevice",
                "iam:ResyncMFADevice"
            ],
            "Resource": [
                "arn:aws:iam::*:mfa/${aws_iam_user.lmcardle.name}",
                "arn:aws:iam::*:user/${aws_iam_user.lmcardle.name}"
            ]
        },
        {
            "Sid": "AllowIndividualUserToDeactivateOnlyTheirOwnMFAOnlyWhenUsingMFA",
            "Effect": "Allow",
            "Action": [
                "iam:DeactivateMFADevice"
            ],
            "Resource": [
                "arn:aws:iam::*:mfa/${aws_iam_user.lmcardle.name}",
                "arn:aws:iam::*:user/${aws_iam_user.lmcardle.name}"
            ],
            "Condition": {
                "Bool": {
                    "aws:MultiFactorAuthPresent": "true"
                }
            }
        },
        {
            "Sid": "BlockMostAccessUnlessSignedInWithMFA",
            "Effect": "Deny",
            "NotAction": [
                "iam:CreateVirtualMFADevice",
                "iam:EnableMFADevice",
                "iam:ListMFADevices",
                "iam:ListUsers",
                "iam:ListVirtualMFADevices",
                "iam:ResyncMFADevice"
            ],
            "Resource": "*",
            "Condition": {
                "BoolIfExists": {
                    "aws:MultiFactorAuthPresent": "false"
                }
            }
        }
    ]
}
EOF
}
