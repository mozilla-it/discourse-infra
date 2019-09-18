variable "region" {
  default = "us-west-2"
}

#############
# Discourse #
#############

variable "discourse-url" {
  default = "discourse.mozilla.org"
}

variable "discourse-elb" {
  default = "fill-me-after-elb-creation"
}

#########
# Redis #
#########

variable "redis-instance" {
  default = "cache.t2.small"
}

variable "redis-num-nodes" {
  default = 1
}

variable "redis-version" {
  default = "5.0.4"
}

variable "redis-parameter-group" {
  default = "default.redis5.0"
}

##########
#  PSQL  #
##########

variable "psql-instance" {
  default = "db.t2.micro"
}

variable "psql-version" {
  default = "10"
}

variable "psql-storage-allocated" {
  default = 10
}

variable "psql-storage-max" {
  default = 100
}

variable "base-build-image" {
  default = "aws/codebuild/standard:2.0"
}

variable "git-repo" {
  default = "https://github.com/mozilla/discourse.mozilla.org"
}

variable "git-branch" {
  default = "codebuild-job"
}

#################
#  Common Tags  #
#################
# See https://mana.mozilla.org/wiki/pages/viewpage.action?spaceKey=SRE&title=Tagging

variable "common-tags" {
  type = "map"

  default = {
    "cost-center"   = "1410"
    "project-name"  = "discourse"
    "project-desc"  = "discourse.mozilla.org"
    "project-email" = "it-sre@mozilla.com"
    "deploy-method" = "terraform"
  }
}

variable "workspace-tags" {
  type    = "map"
  default = {}
}

#################
#  Cloudfront   #
#################
variable "cf-price-class" {
  default = "PriceClass_100"
}

variable "cf-cache-compress" {
  default = "true"
}

variable "cf-alias" {
  default = "cdn-discourse.mozilla.org"
}

#################
#     Email     #
#################
variable "ses-domain" {
  default = "discourse.mozilla.org"
}
