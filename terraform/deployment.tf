resource "aws_codebuild_project" "discourse" {
  name          = "discourse-${terraform.workspace}"
  description   = "CI/CD pipeline for ${terraform.workspace}"
  build_timeout = "30" #In minutes
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE"]
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = var.base-build-image
    type         = "LINUX_CONTAINER"

    # You need "true" here to be able to run Docker daemon inside the building container
    privileged_mode = "true"

    environment_variable {
      name  = "ENV"
      value = terraform.workspace
    }

    environment_variable {
      name  = "ECR"
      value = aws_ecr_repository.discourse-global.repository_url
    }

    environment_variable {
      name  = "CLUSTER"
      value = "k8s-apps-prod-us-west-2"
    }

    environment_variable {
      name  = "CODE_REVISION"
      value = "tests-passed"
    }

    ### Secrets from here:
    environment_variable {
      name  = "DISCOURSE_DB_HOST"
      value = aws_db_instance.discourse.address
    }

    environment_variable {
      name  = "DISCOURSE_DB_PASSWORD"
      value = aws_ssm_parameter.db-secret.value
    }

    environment_variable {
      name  = "DISCOURSE_DB_NAME"
      value = "discourse"
    }

    environment_variable {
      name  = "DISCOURSE_DB_USERNAME"
      value = "discourse"
    }

    environment_variable {
      name  = "DISCOURSE_DB_PORT"
      value = "5432"
    }
  }

  source {
    type      = "GITHUB"
    location  = var.git-repo
    buildspec = "buildspec.yml"
  }

  vpc_config {
    vpc_id = data.terraform_remote_state.deploy.outputs.vpc_id

    security_group_ids = flatten([data.terraform_remote_state.k8s.outputs.worker_security_group_id])
    subnets            = flatten([data.terraform_remote_state.deploy.outputs.private_subnets])
  }

  tags = merge(var.common-tags, var.workspace-tags)
}

#---
# IAM configuration
#---

resource "aws_iam_role" "codebuild" {
  name = "discourse-${terraform.workspace}-codebuild"
  tags = merge(var.common-tags, var.workspace-tags)

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
  role = aws_iam_role.codebuild.name
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
                  "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:subnet/${element(
  data.terraform_remote_state.deploy.outputs.private_subnets,
  0,
  )}",
                  "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:subnet/${element(
  data.terraform_remote_state.deploy.outputs.private_subnets,
  1,
  )}",
                  "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:subnet/${element(
  data.terraform_remote_state.deploy.outputs.private_subnets,
  2,
)}"
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
      "Resource": "arn:aws:ssm:us-west-2:783633885093:parameter/discourse/${terraform.workspace}/*"
    }
  ]
}
POLICY

}

#---
# ECR
#---
resource "aws_ecr_repository" "discourse-global" {
  name  = "discourse"
  tags  = var.common-tags

  image_scanning_configuration {
    scan_on_push = true
  }
}

data "aws_iam_policy_document" "registrypolicy-global" {
  statement {
    actions = [
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
      "ecr:DeleteRepositoryPolicy",
    ]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::783633885093:role/discourse-dev-codebuild",
        "arn:aws:iam::783633885093:role/discourse-stage-codebuild",
        "arn:aws:iam::783633885093:role/discourse-prod-codebuild"
      ]
    }
  }
}

resource "aws_ecr_repository_policy" "registrypolicy-global" {
  repository = aws_ecr_repository.discourse-global.name
  count      = terraform.workspace == "prod" ? "1" : "0"

  policy = data.aws_iam_policy_document.registrypolicy-global.json
}

resource "aws_security_group" "codebuild" {
  name   = "discourse-${terraform.workspace}-codebuild"
  vpc_id = data.terraform_remote_state.deploy.outputs.vpc_id

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

  tags = var.common-tags
}

# TODO create an encrypted secret with a new KMS key
resource "aws_ssm_parameter" "db-secret" {
  name  = "/discourse/${terraform.workspace}/db/secret"
  type  = "String"
  value = "non-real-password"
  tags  = merge(var.common-tags, var.workspace-tags)

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "auth0_client" {
  name  = "/discourse/${terraform.workspace}/auth0-client-id"
  type  = "String"
  value = "non-real-id"
  tags  = merge(var.common-tags, var.workspace-tags)

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "auth0_secret" {
  name  = "/discourse/${terraform.workspace}/auth0-client-secret"
  type  = "String"
  value = "non-real-secret"
  tags  = merge(var.common-tags, var.workspace-tags)

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "akismet-key" {
  name  = "/discourse/${terraform.workspace}/akismet-api-key"
  type  = "String"
  value = "non-real-key"
  tags  = merge(var.common-tags, var.workspace-tags)

  lifecycle {
    ignore_changes = [value]
  }
}

