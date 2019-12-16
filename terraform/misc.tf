# S3 bucket for user uploads
resource "random_id" "bucket" {
  byte_length = 6
}

resource "aws_s3_bucket" "uploads" {
  bucket = "discourse-${terraform.workspace}-uploads-${random_id.bucket.dec}"
  acl    = "private"
  tags   = merge(var.common-tags, var.workspace-tags)

  lifecycle_rule {
    id      = "purge_tombstone"
    enabled = true
    prefix  = "tombstone/"

    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_policy" "uploads_bucket" {
  bucket = aws_s3_bucket.uploads.id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
              "AWS": "*"
						},
            "Action": ["s3:GetObject"],
            "Resource": ["${aws_s3_bucket.uploads.arn}/*"]
				}
    ]
}
POLICY

}

