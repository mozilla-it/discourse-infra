# resource "aws_s3_bucket" "logs_to_papertrail" {
#   bucket = "logs-to-papertrail-lambda-code"
#   acl    = "private"
#   tags   = var.common-tags
# }

# resource "aws_lambda_function" "logs_to_papertrail" {
#   # The sourced code of this function is in https://github.com/Signiant/PaperWatch
#   function_name = "cloudwatch-to-papertrail"
#   handler       = "src/lambda.handler"
#   s3_bucket     = aws_s3_bucket.logs_to_papertrail.id
#   s3_key        = "lambda.zip"
#   description   = "Sends log from a Cloudwatch subscription to Papertrail"
#   tags          = var.common-tags
#   memory_size   = "128"
#   timeout       = "300"
#   runtime       = "nodejs10.x"
#   role          = aws_iam_role.logs_to_papertrail.arn
# }

# resource "aws_lambda_permission" "allow_cloudwatch_to_lambda_logs" {
#   statement_id  = "AllowExecutionFromCloudWatch"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.logs_to_papertrail.function_name
#   principal     = "logs.us-west-2.amazonaws.com"
# }

# resource "aws_iam_role" "logs_to_papertrail" {
#   name = "cloudwatch-logs-to-papertrail"
#   tags = var.common-tags

#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "lambda.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF

# }

