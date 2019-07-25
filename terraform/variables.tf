variable "region" {
  default = "us-west-1"
}

variable "account" {
  default = ""
}

#########
# Redis #
#########

variable "redis-instance" {
  default = ""
}

variable "redis-num-nodes" {
  default = 1
}

variable "redis-version" {
  default = "5.0.4"
}

##########
#  PSQL  #
##########

variable "psql-instance" {
  default = ""
}

variable "psql-version" {
  default = ""
}

variable "psql-storage-allocated" {
  default = 10
}

variable "psql-storage-max" {
  default = 100
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
