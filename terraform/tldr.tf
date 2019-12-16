resource "aws_lambda_function" "tldr" {
  function_name = "discourse-${terraform.workspace}-tldr"
  handler       = "index.handler"
  s3_bucket     = aws_s3_bucket.tldr_code.id
  s3_key        = "discourse-tldr.zip"
  role          = aws_iam_role.lambda_tldr.arn
  description   = "Post the weekly TL;DR email into Discourse ${terraform.workspace}"
  tags          = merge(var.common-tags, var.workspace-tags)
  memory_size   = "256"
  timeout       = "60" # value expressed in seconds
  runtime       = "nodejs8.10"

  depends_on = [
    aws_iam_role_policy_attachment.tldr,
    aws_cloudwatch_log_group.lambda_tldr,
  ]

  environment {
    variables = {
      DISCOURSE_TLDR_API_KEY      = aws_ssm_parameter.tldr_api_key.value
      DISCOURSE_TLDR_API_USERNAME = "tldr"
      DISCOURSE_TLDR_BUCKET       = aws_s3_bucket.tldr_email.id
      DISCOURSE_TLDR_CATEGORY     = "253"
      DISCOURSE_TLDR_URL          = "https://${aws_route53_record.discourse.fqdn}"
    }
  }
}

resource "aws_lambda_permission" "tldr_allow_ses" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tldr.function_name
  principal     = "ses.amazonaws.com"
}

resource "aws_iam_role" "lambda_tldr" {
  name = "discourse-${terraform.workspace}-lambda-tldr"
  tags = merge(var.common-tags, var.workspace-tags)

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_cloudwatch_log_group" "lambda_tldr" {
  name              = "/aws/lambda/discourse-${terraform.workspace}-tldr"
  retention_in_days = 7
  tags              = merge(var.common-tags, var.workspace-tags)
}

resource "aws_cloudwatch_log_subscription_filter" "lambda_tldr_papertrail" {
  name            = "discourse-${terraform.workspace}-tldr-logs-to-papertrail"
  log_group_name  = aws_cloudwatch_log_group.lambda_tldr.name
  destination_arn = aws_lambda_function.logs_to_papertrail.arn
  filter_pattern  = ""
}

resource "aws_iam_policy" "lambda_tldr" {
  name = "discourse-${terraform.workspace}-lambda-tldr"
  path = "/discourse/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    },
    {
      "Action": "s3:GetObject",
      "Resource": [
				"${aws_s3_bucket.tldr_email.arn}",
				"${aws_s3_bucket.tldr_email.arn}/*"
			],
      "Effect": "Allow"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "tldr" {
  role       = aws_iam_role.lambda_tldr.name
  policy_arn = aws_iam_policy.lambda_tldr.arn
}

resource "aws_s3_bucket" "tldr_email" {
  bucket = "discourse-${terraform.workspace}-tldr-email"
  acl    = "private"
  tags   = merge(var.common-tags, var.workspace-tags)
}

resource "aws_s3_bucket" "tldr_code" {
  bucket = "discourse-${terraform.workspace}-tldr-code"
  acl    = "private"
  tags   = merge(var.common-tags, var.workspace-tags)
}

resource "aws_s3_bucket_policy" "tldr_emails" {
  bucket = aws_s3_bucket.tldr_email.id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowSESPuts",
            "Effect": "Allow",
            "Principal": {
                "Service": "ses.amazonaws.com"
						},
            "Action": "s3:PutObject",
            "Resource": "${aws_s3_bucket.tldr_email.arn}/*"
				}
    ]
}
POLICY

}

resource "aws_ssm_parameter" "tldr_api_key" {
  name  = "/discourse/${terraform.workspace}/tldr-api-key"
  type  = "String"
  value = "non-real-key"
  tags  = merge(var.common-tags, var.workspace-tags)

  lifecycle {
    ignore_changes = [value]
  }
}

