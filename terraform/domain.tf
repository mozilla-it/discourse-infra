resource "aws_route53_record" "discourse" {
  zone_id = "${aws_route53_zone.discourse.zone_id}"
  name    = "${var.discourse-url}"
  type    = "A"

  alias {
    name                   = "dualstack.${data.aws_elb.k8s-elb.dns_name}"
    zone_id                = "${data.aws_elb.k8s-elb.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_zone" "discourse" {
  name          = "${var.discourse-url}."
  force_destroy = "false"
  tags          = "${merge(var.common-tags, var.workspace-tags)}"
}

resource "aws_route53_record" "zone_ns" {
  zone_id = "${aws_route53_zone.discourse.zone_id}"
  name    = "${var.discourse-url}"
  type    = "NS"
  ttl     = "172800"

  records = [
    "${aws_route53_zone.discourse.name_servers.0}",
    "${aws_route53_zone.discourse.name_servers.1}",
    "${aws_route53_zone.discourse.name_servers.2}",
    "${aws_route53_zone.discourse.name_servers.3}",
  ]
}

data "aws_route53_zone" "common" {
  name = "itsre-apps.mozit.cloud."
}

data "aws_elb" "k8s-elb" {
  name = "${var.discourse-elb}"
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "${aws_route53_record.discourse.name}"
  validation_method = "DNS"
  tags              = "${merge(var.common-tags, var.workspace-tags)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  name    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  zone_id = "${aws_route53_zone.discourse.id}"
  records = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
  ttl     = 300
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = "${aws_acm_certificate.cert.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]

  # This is a hack to avoid trying to create this resources, because it was created manually
  # and can't be imported.
  # Once the CDN in prod is using cdn.discourse.mozilla.org we could recreate the cert
  # so get rid of this.
  count = "${terraform.workspace == "prod" ? "0" : "1"}"
}
