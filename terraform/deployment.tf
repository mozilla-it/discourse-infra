resource "aws_codebuild_project" "discourse" {
  name          = "discourse-${terraform.workspace}"
  description   = "CI/CD pipeline for ${terraform.workspace}"
  build_timeout = "30"                                        #In minutes
  service_role  = "${aws_iam_role.codebuild.arn}"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE"]
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "${var.base-build-image}"
    type         = "LINUX_CONTAINER"

    # You need "true" here to be able to run Docker daemon inside the building container
    privileged_mode = "true"

    environment_variable {
      "name"  = "DB_HOST"
      "value" = "${aws_db_instance.discourse.address}"
    }

    environment_variable {
      "name"  = "REDIS_HOST"
      "value" = "${aws_elasticache_cluster.discourse.cache_nodes.0.address}"
    }

    environment_variable {
      "name"  = "ECR"
      "value" = "${aws_ecr_repository.discourse.repository_url}"
    }

    environment_variable {
      "name"  = "CLUSTER"
      "value" = "k8s-apps-prod-us-west-2"
    }

    environment_variable {
      "name"  = "D_HOSTNAME"
      "value" = "${aws_route53_record.discourse.fqdn}"
    }

    environment_variable {
      "name"  = "SMTP_USER"
      "value" = "${aws_iam_access_key.smtp.id}"
    }

    environment_variable {
      "name"  = "SMTP_PW"
      "value" = "${aws_iam_access_key.smtp.ses_smtp_password}"
    }
  }

  source {
    type      = "GITHUB"
    location  = "${var.git-repo}"
    buildspec = "buildspec.yml"
  }

  vpc_config {
    vpc_id = "${data.terraform_remote_state.deploy.vpc_id}"

    #security_group_ids = ["${aws_security_group.discourse-db.id}", "${aws_security_group.discourse-redis.id}", "${aws_security_group.codebuild.id}"]
    security_group_ids = ["${data.terraform_remote_state.k8s.worker_security_group_id}"]
    subnets            = ["${data.terraform_remote_state.deploy.private_subnets}"]
  }

  tags = "${merge(var.common-tags, var.workspace-tags)}"
}

#---
# IAM configuration
#---

resource "aws_iam_role" "codebuild" {
  name = "discourse-${terraform.workspace}-codebuild"
  tags = "${merge(var.common-tags, var.workspace-tags)}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codebuild" {
  role = "${aws_iam_role.codebuild.name}"
  name = "discourse-${terraform.workspace}-codebuild"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:*",
        "eks:DescribeCluster"
      ],
      "Resource": "*"
    },
		{
      "Effect": "Allow",
      "Action": [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeDhcpOptions",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
          "ec2:CreateNetworkInterfacePermission"
      ],
      "Resource": "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:network-interface/*",
      "Condition": {
          "StringEquals": {
              "ec2:Subnet": [
                  "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:subnet/${element(data.terraform_remote_state.deploy.private_subnets, 0)}",
                  "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:subnet/${element(data.terraform_remote_state.deploy.private_subnets, 1)}",
                  "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:subnet/${element(data.terraform_remote_state.deploy.private_subnets, 2)}"
              ],
              "ec2:AuthorizedService": "codebuild.amazonaws.com"
          }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters"
      ],
      "Resource": "${aws_ssm_parameter.db-secret.arn}"
    }
  ]
}
POLICY
}

#---
# ECR
#---
resource "aws_ecr_repository" "discourse" {
  name = "discourse-${terraform.workspace}"
  tags = "${merge(var.common-tags, var.workspace-tags)}"
}

resource "aws_ecr_repository_policy" "registrypolicy" {
  repository = "${aws_ecr_repository.discourse.name}"

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
              "AWS": "${aws_iam_role.codebuild.arn}"
            },
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:DeleteRepository",
                "ecr:BatchDeleteImage",
                "ecr:SetRepositoryPolicy",
                "ecr:DeleteRepositoryPolicy"
            ]
        }
    ]
}
EOF
}

resource "aws_security_group" "codebuild" {
  name   = "discourse-${terraform.workspace}-codebuild"
  vpc_id = "${data.terraform_remote_state.deploy.vpc_id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${var.common-tags}"
}

# TODO create an encrypted secret with a new KMS key
resource "aws_ssm_parameter" "db-secret" {
  name  = "/discourse/dev/db/secret"
  type  = "String"
  value = "non-real-password"
  tags  = "${merge(var.common-tags, var.workspace-tags)}"

  lifecycle {
    ignore_changes = ["value"]
  }
}
