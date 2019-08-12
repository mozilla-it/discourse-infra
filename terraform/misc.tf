resource "random_id" "bucket" {
  byte_length = 6
}

resource "aws_s3_bucket" "uploads" {
  bucket = "discourse-${terraform.workspace}-uploads-${random_id.bucket.dec}"
  acl    = "private"
  tags = "${merge(var.common-tags, var.workspace-tags)}"
}
