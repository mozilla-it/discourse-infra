####################
#      Users       #
####################

# Alberto
resource "aws_iam_user" "adelbarrio" {
  name = "adelbarrio"

  # Not supported by EKS:
  #path = "/discourse/"
  tags = "${var.common-tags}"
}

resource "aws_iam_user_policy" "adelbarrio_mfa" {
  name = "allow-${aws_iam_user.adelbarrio.name}-self-manage-mfa"
  user = "${aws_iam_user.adelbarrio.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowIndividualUserToListOnlyTheirOwnMFA",
      "Effect": "Allow",
      "Action": "iam:ListMFADevices",
      "Resource": [
        "arn:aws:iam::*:mfa/*",
        "arn:aws:iam::*:user/${aws_iam_user.adelbarrio.name}"
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
        "arn:aws:iam::*:mfa/${aws_iam_user.adelbarrio.name}",
        "arn:aws:iam::*:user/${aws_iam_user.adelbarrio.name}"
      ]
    },
    {
      "Sid": "AllowIndividualUserToDeactivateOnlyTheirOwnMFAOnlyWhenUsingMFA",
      "Effect": "Allow",
      "Action": "iam:DeactivateMFADevice",
      "Resource": [
        "arn:aws:iam::*:mfa/${aws_iam_user.adelbarrio.name}",
        "arn:aws:iam::*:user/${aws_iam_user.adelbarrio.name}"
      ],
      "Condition": {
         "Bool": {
           "aws:MultiFactorAuthPresent": "true"
          }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
				"iam:ChangePassword",
        "iam:CreateAccessKey",
        "iam:DeleteAccessKey",
        "iam:GetAccessKeyLastUsed",
        "iam:GetUser",
        "iam:ListAccessKeys",
        "iam:UpdateAccessKey"
			],
      "Resource": "arn:aws:iam::783633885093:user/${aws_iam_user.adelbarrio.id}"
    }
  ]
}
EOF
}

resource "aws_iam_user_login_profile" "adelbarrio" {
  user                    = "${aws_iam_user.adelbarrio.name}"
  pgp_key                 = "keybase:adelbarrio"
  password_reset_required = false

  lifecycle {
    ignore_changes = ["password_length", "password_reset_required", "pgp_key"]
  }
}

output "password_adelbarrio" {
  value = "${aws_iam_user_login_profile.adelbarrio.encrypted_password}"
}

# Leo
resource "aws_iam_user" "lmcardle" {
  name = "lmcardle"

  # Not supported by EKS:
  #path = "/discourse/"
  tags = "${var.common-tags}"
}

resource "aws_iam_user_policy" "lmcardle_mfa" {
  name = "allow-${aws_iam_user.lmcardle.name}-self-manage-mfa"
  user = "${aws_iam_user.lmcardle.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowIndividualUserToListOnlyTheirOwnMFA",
      "Effect": "Allow",
      "Action": "iam:ListMFADevices",
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
      "Action": "iam:DeactivateMFADevice",
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
      "Effect": "Allow",
      "Action": [
				"iam:ChangePassword",
        "iam:CreateAccessKey",
        "iam:DeleteAccessKey",
        "iam:GetAccessKeyLastUsed",
        "iam:GetUser",
        "iam:ListAccessKeys",
        "iam:UpdateAccessKey"
			],
      "Resource": "arn:aws:iam::783633885093:user/${aws_iam_user.lmcardle.id}"
    }
  ]
}
EOF
}

resource "aws_iam_user_login_profile" "lmcardle" {
  user                    = "${aws_iam_user.lmcardle.name}"
  pgp_key                 = "keybase:leomca"
  password_reset_required = false

  lifecycle {
    ignore_changes = ["password_length", "password_reset_required", "pgp_key"]
  }
}

output "password_lmcardle" {
  value = "${aws_iam_user_login_profile.lmcardle.encrypted_password}"
}

#####################
#   Group policies  #
#####################

resource "aws_iam_group_membership" "discourse" {
  name  = "discourse-developers"
  users = ["${aws_iam_user.adelbarrio.name}", "${aws_iam_user.lmcardle.name}"]
  group = "${aws_iam_group.developers.name}"
}

resource "aws_iam_group" "developers" {
  name = "developers"
  path = "/discourse/"
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
        "eks:ListClusters",
				"codebuild:ListProjects"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "iam:GetAccountPasswordPolicy",
       "Resource": "*"
    },
    {
      "Action": [
        "codebuild:*"
      ],
      "Effect": "Allow",
      "Resource": [
				"arn:aws:codebuild:us-west-2:783633885093:project/discourse-staging",
				"arn:aws:codebuild:us-west-2:783633885093:project/discourse-dev"
			]
    },
    {
      "Effect": "Allow",
      "Action": [
        "events:DescribeRule",
        "events:ListTargetsByRule",
        "events:ListRuleNamesByTarget",
				"cloudwatch:GetMetricStatistics",
        "s3:GetBucketLocation",
        "s3:ListAllMyBuckets",
        "logs:GetLogEvents"
			],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:PutParameter"
      ],
      "Resource": "arn:aws:ssm:*:*:parameter/CodeBuild/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
				"arn:aws:s3:::discourse-dev-incoming-email-processor",
				"arn:aws:s3:::discourse-staging-incoming-email-processor"
			]
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
