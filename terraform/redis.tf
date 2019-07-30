resource "aws_elasticache_cluster" "discourse" {
  cluster_id           = "discourse-${terraform.workspace}-redis"
  engine               = "redis"
  node_type            = "${var.redis-instance}"
  num_cache_nodes      = "${var.redis-num-nodes}"
  engine_version       = "${var.redis-version}"
  parameter_group_name = "default.redis${var.redis-version}"
	subnet_group_name    = "${aws_db_subnet_group.discourse-redis.id}"
	security_group_ids   = ["${aws_security_group.discourse-redis.id}"]
  tags                 = "${merge(var.common-tags, var.workspace-tags)}"
}

resource "aws_db_subnet_group" "discourse-redis" {
  name        = "discourse-${terraform.workspace}-redis"
  description = "Subnet for discourse ${terraform.workspace} Redis cluster"
  subnet_ids  = ["${data.terraform_remote_state.deploy.private_subnets}"]
  tags        = "${merge(var.common-tags, var.workspace-tags)}"
}

resource "aws_security_group" "discourse-redis" {
  name   = "discourse-${terraform.workspace}-redis"
  vpc_id = "${data.terraform_remote_state.deploy.vpc_id}"

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "TCP"
    cidr_blocks = ["172.16.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(var.common-tags, var.workspace-tags)}"
}

