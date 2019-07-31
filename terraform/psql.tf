resource "aws_db_instance" "discourse" {
  identifier                  = "discourse-${terraform.workspace}"
  storage_type                = "gp2"
  engine                      = "postgres"
  engine_version              = "${var.psql-version}"
  instance_class              = "${var.psql-instance}"
  allocated_storage           = "${var.psql-storage-allocated}"
  max_allocated_storage       = "${var.psql-storage-max}"
  multi_az                    = "${terraform.workspace == "prod" ? true : false}"
  allow_major_version_upgrade = true
  name                        = "discourse"
  username                    = "discourse"
  password                    = "oneTimePassword"
  backup_retention_period     = 15
  db_subnet_group_name        = "${aws_db_subnet_group.discourse-db.id}"
  vpc_security_group_ids      = ["${aws_security_group.discourse-db.id}"]
  tags                        = "${merge(var.common-tags, var.workspace-tags)}"
}

resource "aws_db_subnet_group" "discourse-db" {
  name        = "discourse-${terraform.workspace}-db"
  description = "Subnet for discourse ${terraform.workspace} DB"
  subnet_ids  = ["${data.terraform_remote_state.deploy.private_subnets}"]
  tags        = "${merge(var.common-tags, local.subnet_db_workspace_tags)}"
}

resource "aws_security_group" "discourse-db" {
  name   = "discourse-${terraform.workspace}-db"
  vpc_id = "${data.terraform_remote_state.deploy.vpc_id}"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "TCP"
    cidr_blocks = ["172.16.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(var.common-tags, local.subnet_db_workspace_tags)}"
}

locals {
  subnet_db_name_tags = {
    Name = "discourse-${terraform.workspace}-redis"
  }

  subnet_db_workspace_tags = "${merge(local.subnet_redis_name_tags, var.workspace-tags)}"
}

output "rds_endpoint" {
  value = "${aws_db_instance.discourse.endpoint}"
}
