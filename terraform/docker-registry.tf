resource "aws_ecr_repository" "discourse" {
  name = "discourse-${terraform.workspace}"
  tags = "${merge(var.common-tags, var.workspace-tags)}"
}
