resource "aws_ses_domain_identity" "main" {
  domain = "${var.ses-domain}"
}

resource "aws_ses_domain_identity_verification" "main" {
  domain     = "${aws_ses_domain_identity.main.id}"
  depends_on = ["aws_route53_record.ses_verification"]
}

resource "aws_route53_record" "ses_verification" {
  zone_id = "${aws_route53_zone.discourse-ses.id}"
  name    = "_amazonses.${aws_ses_domain_identity.main.id}"
  type    = "TXT"
  ttl     = "600"
  records = ["${aws_ses_domain_identity.main.verification_token}"]
}

resource "aws_route53_zone" "discourse-ses" {
  name = "${var.ses-domain}."
  tags = "${merge(var.common-tags, var.workspace-tags)}"
}

resource "aws_ses_domain_dkim" "main" {
  domain = "${aws_ses_domain_identity.main.domain}"
}

resource "aws_route53_record" "dkim" {
  count   = 3
  zone_id = "${aws_route53_zone.discourse-ses.id}"
  name    = "${format("%s._domainkey.%s", element(aws_ses_domain_dkim.main.dkim_tokens, count.index), aws_ses_domain_identity.main.domain)}"
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.main.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

#
# SES MAIL FROM Domain
#

resource "aws_ses_domain_mail_from" "main" {
  domain           = "${aws_ses_domain_identity.main.domain}"
  mail_from_domain = "mail.${aws_ses_domain_identity.main.domain}"
}

# SPF validaton record
resource "aws_route53_record" "spf_mail_from" {
  zone_id = "${aws_route53_zone.discourse-ses.id}"
  name    = "${aws_ses_domain_mail_from.main.mail_from_domain}"
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}

resource "aws_route53_record" "spf_domain" {
  zone_id = "${aws_route53_zone.discourse-ses.id}"
  name    = "${aws_ses_domain_identity.main.domain}"
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}

resource "aws_route53_record" "mx_send_mail_from" {
  zone_id = "${aws_route53_zone.discourse-ses.id}"
  name    = "${aws_ses_domain_mail_from.main.mail_from_domain}"
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.${var.region}.amazonses.com"]
}

# Receiving MX Record
resource "aws_route53_record" "mx_receive" {
  zone_id = "${aws_route53_zone.discourse-ses.id}"
  name    = "${aws_ses_domain_identity.main.domain}"
  type    = "MX"
  ttl     = "600"
  records = ["10 inbound-smtp.${var.region}.amazonaws.com"]
}

# DMARC TXT Record
resource "aws_route53_record" "txt_dmarc" {
  zone_id = "${aws_route53_zone.discourse-ses.id}"
  name    = "_dmarc.${aws_ses_domain_identity.main.domain}"
  type    = "TXT"
  ttl     = "600"
  records = ["v=DMARC1; p=reject;rua=mailto:postmaster@${aws_ses_domain_identity.main.domain};"]
}

# SES Receipt Rule
resource "aws_ses_receipt_rule" "store_and_forward_email" {
  name          = "discourse-${terraform.workspace}-store-and-forward-email"
  rule_set_name = "${aws_ses_receipt_rule_set.discourse.id}"
  enabled       = true
  scan_enabled  = true
  depends_on    = ["aws_ses_receipt_rule_set.discourse"]
  count         = "${terraform.workspace == "prod" ? "1" : "0"}"
  recipients    = ["${aws_ses_domain_identity.main.domain}"]

  s3_action {
    position    = 1
    bucket_name = "${aws_s3_bucket.incoming_email.id}"
  }

  lambda_action {
    position     = 2
    function_arn = "${aws_lambda_function.incoming_email.arn}"
  }
}

resource "aws_ses_receipt_rule" "tldr" {
  name          = "discourse-${terraform.workspace}-tldr"
  rule_set_name = "${aws_ses_receipt_rule_set.discourse.id}"
  enabled       = true
  scan_enabled  = true
  depends_on    = ["aws_ses_receipt_rule_set.discourse"]
  count         = "${terraform.workspace == "prod" ? "1" : "0"}"
  recipients    = ["tldr@${aws_ses_domain_identity.main.domain}"]

  s3_action {
    position    = 1
    bucket_name = "${aws_s3_bucket.tldr_email.id}"
  }

  lambda_action {
    position     = 2
    function_arn = "${aws_lambda_function.tldr.arn}"
  }
}

resource "aws_ses_receipt_rule_set" "discourse" {
  # Only one receipt rule set can be active at a time,
  # so we don't want to make it workspace dependent
  count = "${terraform.workspace == "prod" ? "1" : "0"}"

  rule_set_name = "discourse"
}

resource "aws_ses_active_receipt_rule_set" "discourse" {
  rule_set_name = "${aws_ses_receipt_rule_set.discourse.id}"
  count         = "${terraform.workspace == "prod" ? "1" : "0"}"
}

resource "aws_s3_bucket" "incoming_email" {
  bucket = "discourse-${terraform.workspace}-email-${random_id.bucket.dec}"
  acl    = "private"
  tags   = "${merge(var.common-tags, var.workspace-tags)}"

  lifecycle_rule {
    enabled = true

    expiration {
      days = 21
    }
  }
}

resource "aws_s3_bucket_policy" "incoming_email_policy" {
  bucket = "${aws_s3_bucket.incoming_email.id}"

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
            "Resource": "${aws_s3_bucket.incoming_email.arn}/*"
				}
    ]
}
POLICY
}

# Create SMTP creds:
resource "aws_iam_access_key" "smtp" {
  user = "${aws_iam_user.smtp.name}"
}

resource "aws_iam_user" "smtp" {
  name = "discourse-${terraform.workspace}-smtp"
  path = "/discourse/${terraform.workspace}/"
  tags = "${merge(var.common-tags, var.workspace-tags)}"
}

resource "aws_iam_user_policy" "smtp" {
  name = "discourse-${terraform.workspace}-smtp"
  user = "${aws_iam_user.smtp.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ses:SendRawEmail"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

######################################
#  Post incoming email to Discourse  #
######################################
resource "aws_lambda_function" "incoming_email" {
  function_name = "discourse-${terraform.workspace}-process-email"
  handler       = "export.main"
  s3_bucket     = "${aws_s3_bucket.email_lambda_code.id}"
  s3_key        = "lambda.zip"
  role          = "${aws_iam_role.lambda_incoming_email.arn}"
  description   = "Process incoming email for Discourse ${terraform.workspace}"
  tags          = "${merge(var.common-tags, var.workspace-tags)}"
  memory_size   = "128"
  timeout       = "15"                                                          # value expressed in seconds
  runtime       = "provided"

  depends_on = ["aws_iam_role_policy_attachment.lambda_logs", "aws_cloudwatch_log_group.lambda_incoming_email"]

  environment {
    variables = {
      DISCOURSE_API_KEY         = "${aws_ssm_parameter.in_email_api_key.value}"
      DISCOURSE_API_USERNAME    = "system"
      DISCOURSE_EMAIL_IN_BUCKET = "${aws_s3_bucket.incoming_email.id}"
      DISCOURSE_URL             = "https://${aws_route53_record.discourse.fqdn}"
      REJECTED_RECIPIENTS       = "tldr@${var.ses-domain}"
    }
  }
}

resource "aws_lambda_permission" "allow_ses" {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.incoming_email.function_name}"
  principal     = "ses.amazonaws.com"
}

resource "aws_iam_role" "lambda_incoming_email" {
  name = "discourse-${terraform.workspace}-lambda-process-email"
  tags = "${merge(var.common-tags, var.workspace-tags)}"

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

resource "aws_cloudwatch_log_group" "lambda_incoming_email" {
  name              = "/aws/lambda/discourse-${terraform.workspace}-process-email"
  retention_in_days = 7
  tags              = "${merge(var.common-tags, var.workspace-tags)}"
}

resource "aws_cloudwatch_log_subscription_filter" "lambda_incoming_email_to_papertrail" {
  name            = "discourse-${terraform.workspace}-processed-email-logs-to-papertrail"
  log_group_name  = "${aws_cloudwatch_log_group.lambda_incoming_email.name}"
  destination_arn = "${aws_lambda_function.logs_to_papertrail.arn}"
  filter_pattern  = ""
}

resource "aws_iam_policy" "lambda_incoming_email" {
  name = "discourse-${terraform.workspace}-lambda-email"
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
				"${aws_s3_bucket.incoming_email.arn}",
				"${aws_s3_bucket.incoming_email.arn}/*"
			],
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = "${aws_iam_role.lambda_incoming_email.name}"
  policy_arn = "${aws_iam_policy.lambda_incoming_email.arn}"
}

# This bucket will store the code of the Lambda function used to process
# incoming emails.
resource "aws_s3_bucket" "email_lambda_code" {
  bucket = "discourse-${terraform.workspace}-incoming-email-processor"
  acl    = "private"
  tags   = "${merge(var.common-tags, var.workspace-tags)}"
}

resource "aws_ssm_parameter" "in_email_api_key" {
  name  = "/discourse/${terraform.workspace}/in-email-api-key"
  type  = "String"
  value = "non-real-key"
  tags  = "${merge(var.common-tags, var.workspace-tags)}"

  lifecycle {
    ignore_changes = ["value"]
  }
}
