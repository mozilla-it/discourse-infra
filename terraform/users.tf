# ####################
# #      Users       #
# ####################

# // Grant access to users via MAWS
# module "discourse_developers" {
#   create_role  = terraform.workspace == "prod" ? "1" : "0"
#   source       = "github.com/mozilla-it/terraform-modules//aws/maws-roles"
#   role_name    = "maws-discourse-developers"
#   role_mapping = ["aws_discourse_dev"]
#   policy_arn   = terraform.workspace == "prod" ? [aws_iam_policy.developers[0].arn] : [""]
# }

# resource "aws_iam_policy" "developers" {
#   count  = terraform.workspace == "prod" ? "1" : "0"
#   name   = "discourseDevelopersPolicy"
#   path   = "/"
#   policy = data.aws_iam_policy_document.developers.json
# }

# data "aws_iam_policy_document" "developers" {

#   statement {
#     sid       = "DiscourseEks"
#     actions   = ["eks:DescribeCluster"]
#     resources = ["*"]
#   }

#   statement {
#     sid     = "DiscourseCodebuild"
#     actions = ["codebuild:*"]
#     resources = [
#       "arn:aws:codebuild:us-west-2:783633885093:project/discourse-stage",
#       "arn:aws:codebuild:us-west-2:783633885093:project/discourse-dev",
#       "arn:aws:codebuild:us-west-2:783633885093:project/discourse-prod"
#     ]
#   }

#   statement {
#     sid     = "DiscourseCodebuildList"
#     actions = ["codebuild:ListProjects"]
#     resources = ["*"]
#   }

#   statement {
#     sid     = "DiscourseCodebuildLogs"
#     actions = ["logs:GetLogEvents"]
#     resources = ["arn:aws:logs:us-west-2:783633885093:log-group:/aws/codebuild/discourse-*:*:*"]
#   }

#   # Need for CodeBuild UI
#   statement {
#     sid     = "DiscourseParameters"
#     actions = ["ssm:*"]
#     resources = ["arn:aws:ssm:us-west-2:783633885093:paramter:/discourse/*"]
#   }

#   # Need for CodeBuild UI
#   statement {
#     sid     = "DiscourseParametersList"
#     actions = ["ssm:DescribeParameters"]
#     resources = ["arn:aws:ssm:us-west-2:783633885093:*"]
#   }

#   # Need for CodeBuild UI
#   statement {
#     sid       = "DiscourseS3List"
#     actions   = ["s3:ListAllMyBuckets"]
#     resources = ["*"]
#   }

#   statement {
#     sid       = "DiscourseS3"
#     actions   = ["s3:*"]
#     resources = ["arn:aws:s3:::discourse-*"]
#   }

#   statement {
#     sid = "DiscourseSES"
#     actions = [
#       "ses:DescribeActiveReceiptRuleSet",
#       "ses:DescribeReceiptRule",
#       "ses:DescribeReceiptRuleSet",
#       "ses:ListReceiptRuleSets"
#     ]
#     resources = ["*"]
#   }

#   statement {
#     sid = "DiscourseLambdaRO"
#     actions = [
#       "lambda:GetAccountSettings",
#       "lambda:ListFunctions",
#       "lambda:ListTags",
#       "lambda:GetEventSourceMapping",
#       "lambda:ListEventSourceMappings"
#     ]
#     resources = ["arn:aws:lambda:::discourse-*"]
#   }

#   statement {
#     sid = "DiscourseLambdaSourceMapping"
#     actions = [
#       "lambda:DeleteEventSourceMapping",
#       "lambda:UpdateEventSourceMapping",
#       "lambda:CreateEventSourceMapping"
#     ]
#     resources = ["*"]
#     condition {
#       test     = "StringLike"
#       variable = "lambda:FunctionArn"
#       values   = ["arn:aws:lambda:*:*:function:discourse-*"]
#     }
#   }
# }
