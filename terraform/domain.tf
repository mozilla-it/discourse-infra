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
