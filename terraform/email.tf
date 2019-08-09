resource "aws_ses_domain_identity" "main" {
  domain = "${aws_route53_record.discourse.fqdn}"
}

resource "aws_ses_domain_identity_verification" "main" {
  domain     = "${aws_ses_domain_identity.main.id}"
  depends_on = ["aws_route53_record.ses_verification"]
}

resource "aws_route53_record" "ses_verification" {
  zone_id = "${data.aws_route53_zone.common.id}"
  name    = "_amazonses.${aws_ses_domain_identity.main.id}"
  type    = "TXT"
  ttl     = "600"
  records = ["${aws_ses_domain_identity.main.verification_token}"]
}

resource "aws_ses_domain_dkim" "main" {
  domain = "${aws_ses_domain_identity.main.domain}"
}

resource "aws_route53_record" "dkim" {
  count   = 3
  zone_id = "${data.aws_route53_zone.common.id}"
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
  mail_from_domain = "discourse.${aws_ses_domain_identity.main.domain}"
}

# SPF validaton record
resource "aws_route53_record" "spf_mail_from" {
  zone_id = "${data.aws_route53_zone.common.id}"
  name    = "${aws_ses_domain_mail_from.main.mail_from_domain}"
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}

resource "aws_route53_record" "spf_domain" {
  zone_id = "${data.aws_route53_zone.common.id}"
  name    = "${aws_ses_domain_identity.main.domain}"
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}

resource "aws_route53_record" "mx_send_mail_from" {
  zone_id = "${data.aws_route53_zone.common.id}"
  name    = "${aws_ses_domain_mail_from.main.mail_from_domain}"
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.${var.region}.amazonses.com"]
}

# Receiving MX Record
resource "aws_route53_record" "mx_receive" {
  zone_id = "${data.aws_route53_zone.common.id}"
  name    = "${aws_ses_domain_identity.main.domain}"
  type    = "MX"
  ttl     = "600"
  records = ["10 inbound-smtp.${var.region}.amazonaws.com"]
}

#
# DMARC TXT Record
#
#resource "aws_route53_record" "txt_dmarc" {
#  zone_id = "${data.aws_route53_zone.common.id}"
#  name    = "_dmarc.${var.domain_name}"
#  type    = "TXT"
#  ttl     = "600"
#  records = ["v=DMARC1; p=none; rua=mailto:${var.dmarc_rua};"]
#}

#
# SES Receipt Rule
#

#resource "aws_ses_receipt_rule" "main" {
#  name          = "${format("%s-s3-rule", local.dash_domain)}"
#  rule_set_name = "${var.ses_rule_set}"
#  recipients    = "${var.from_addresses}"
#  enabled       = true
#  scan_enabled  = true
#
#  s3_action {
#    position = 1
#
#    bucket_name       = "${var.receive_s3_bucket}"
#    object_key_prefix = "${var.receive_s3_prefix}"
#  }
#}

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

