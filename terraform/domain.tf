resource "aws_route53_record" "discourse" {
  zone_id = "${data.aws_route53_zone.common.zone_id}"
  name    = "discourse-dev.itsre-apps.mozit.cloud"
  type    = "A"

  alias {
    name                   = "dualstack.${data.aws_elb.k8s-elb.dns_name}"
    zone_id                = "${data.aws_elb.k8s-elb.zone_id}"
    evaluate_target_health = false
  }
}

data "aws_route53_zone" "common" {
 name = "itsre-apps.mozit.cloud."
}

data "aws_elb" "k8s-elb" {
 name = "ab30fe62db90e11e99aba06db27de6a9"
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "${aws_route53_record.discourse.name}"
  validation_method = "DNS"
  tags = "${merge(var.common-tags, var.workspace-tags)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  name    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.common.id}"
  records = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = "${aws_acm_certificate.cert.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}

