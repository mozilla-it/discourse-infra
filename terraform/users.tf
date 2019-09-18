####################
#      Users       #
####################

# Alberto
resource "aws_iam_user" "adelbarrio" {
  name = "adelbarrio"
	count = "${terraform.workspace == "prod" ? "1" : "0"}"

  # Not supported by EKS:
  #path = "/discourse/"
  tags = "${var.common-tags}"
}

resource "aws_iam_user_policy" "adelbarrio_mfa" {
  name = "allow-${aws_iam_user.adelbarrio.name}-self-manage-mfa"
  user = "${aws_iam_user.adelbarrio.name}"
	count = "${terraform.workspace == "prod" ? "1" : "0"}"

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
	count = "${terraform.workspace == "prod" ? "1" : "0"}"

  lifecycle {
    ignore_changes = ["password_length", "password_reset_required", "pgp_key"]
  }
}

# Leo
resource "aws_iam_user" "lmcardle" {
  name = "lmcardle"
	count = "${terraform.workspace == "prod" ? "1" : "0"}"

  # Not supported by EKS:
  #path = "/discourse/"
  tags = "${var.common-tags}"
}

resource "aws_iam_user_policy" "lmcardle_mfa" {
  name = "allow-${aws_iam_user.lmcardle.name}-self-manage-mfa"
  user = "${aws_iam_user.lmcardle.name}"
	count = "${terraform.workspace == "prod" ? "1" : "0"}"

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
	count = "${terraform.workspace == "prod" ? "1" : "0"}"

  lifecycle {
    ignore_changes = ["password_length", "password_reset_required", "pgp_key"]
  }
}

#####################
#   Group policies  #
#####################

resource "aws_iam_group_membership" "discourse" {
  name  = "discourse-developers"
	count = "${terraform.workspace == "prod" ? "1" : "0"}"
  users = ["${aws_iam_user.adelbarrio.name}", "${aws_iam_user.lmcardle.name}"]
  group = "${aws_iam_group.developers.name}"
}

resource "aws_iam_group" "developers" {
  name = "developers"
  path = "/discourse/"
	count = "${terraform.workspace == "prod" ? "1" : "0"}"
}

resource "aws_iam_group_policy" "discourse-devs" {
  name  = "discourse-developer-policy"
  group = "${aws_iam_group.developers.id}"
	count = "${terraform.workspace == "prod" ? "1" : "0"}"

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
				"arn:aws:codebuild:us-west-2:783633885093:project/discourse-dev",
				"arn:aws:codebuild:us-west-2:783633885093:project/discourse-prod"
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
				"arn:aws:s3:::discourse-*"

			]
    }
  ]
}
EOF
}

resource "aws_iam_group_policy" "self-managed-mfa" {
  name  = "self-managed-mfa"
  group = "${aws_iam_group.developers.id}"
	count = "${terraform.workspace == "prod" ? "1" : "0"}"

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

resource "aws_iam_group_policy" "lambda" {
  name  = "discourse-developers-lambda-access"
  group = "${aws_iam_group.developers.id}"
	count = "${terraform.workspace == "prod" ? "1" : "0"}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
			{
        "Sid": "LambdaReadOnlyPermissions",
        "Effect": "Allow",
        "Action": [
            "lambda:GetAccountSettings",
            "lambda:ListFunctions",
            "lambda:ListTags",
            "lambda:GetEventSourceMapping",
            "lambda:ListEventSourceMappings",
            "iam:ListRoles"
        ],
         "Resource": "*"
        },
        {
          "Sid": "LambdaDevelopFunctions",
          "Effect": "Allow",
          "NotAction": [
             "lambda:AddPermission",
             "lambda:PutFunctionConcurrency"
          ],
          "Resource": "arn:aws:lambda:*:*:function:discourse-*"
        },
        {
          "Sid": "DiscourseLambdaDevelopEventSourceMappings",
           "Effect": "Allow",
           "Action": [
              "lambda:DeleteEventSourceMapping",
              "lambda:UpdateEventSourceMapping",
              "lambda:CreateEventSourceMapping"
           ],
           "Resource": "*",
           "Condition": {
              "StringLike": {
                 "lambda:FunctionArn": "arn:aws:lambda:*:*:function:discourse-*"
               }
            }
        },
        {
          "Sid": "DiscoursLambdaeViewLogs",
          "Effect": "Allow",
          "Action": [
              "logs:*"
          ],
          "Resource": "arn:aws:logs:*:*:log-group:/aws/lambda/discourse-*"
        },
        {
          "Sid": "DiscoursLambdaeViewMetrics",
          "Effect": "Allow",
          "Action": [
              "cloudwatch:GetMetricStatistics",
							"cloudwatch:GetMetricData"
          ],
          "Resource": "*"
        }
    ]
}
EOF
}
