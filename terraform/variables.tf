variable "region" {
  default = "us-west-2"
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
  default = "11"
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
  default = "https://github.com/The-smooth-operator/discourse.mozilla.org.git"
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
