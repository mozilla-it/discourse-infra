resource "aws_cloudfront_distribution" "discourse_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = ["cdn-${var.discourse-url}"]
  comment             = "Discourse ${terraform.workspace} CDN"
  price_class         = "${var.cf-price-class}"
  depends_on          = ["aws_acm_certificate.cdn", "aws_acm_certificate_validation.cdn"]

  origin {
    domain_name = "${aws_route53_record.discourse.fqdn}"
    origin_id   = "discourse-pull-origin"
    origin_path = ""

    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "https-only"                    # Only talk to the origin over HTTPS
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  logging_config {
    include_cookies = false
    bucket          = "${aws_s3_bucket.cdn_logs.bucket_domain_name}"
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "discourse-pull-origin"
    compress         = "${var.cf-cache-compress}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 360
    max_ttl                = 3600
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = "${merge(var.common-tags, var.workspace-tags)}"

  viewer_certificate {
    acm_certificate_arn      = "${aws_acm_certificate.cdn.arn}"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1"
  }
}

resource "aws_acm_certificate" "cdn" {
  domain_name       = "cdn-${var.discourse-url}"
  validation_method = "DNS"
  tags              = "${merge(var.common-tags, var.workspace-tags)}"
  provider          = "aws.us-east-1"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cdn_cert_validation" {
  name    = "${aws_acm_certificate.cdn.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.cdn.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.common.id}"
  records = ["${aws_acm_certificate.cdn.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cdn" {
  certificate_arn         = "${aws_acm_certificate.cdn.arn}"
  validation_record_fqdns = ["${aws_route53_record.cdn_cert_validation.fqdn}"]
  provider                = "aws.us-east-1"
}

resource "random_id" "cdn_logs" {
  byte_length = 6
}

resource "aws_s3_bucket" "cdn_logs" {
  bucket = "discourse-${terraform.workspace}-cdn-logs-${random_id.cdn_logs.dec}"
  acl    = "private"
  tags   = "${merge(var.common-tags, var.workspace-tags)}"
}
