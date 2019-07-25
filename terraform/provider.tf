provider "aws" {
  region = "us-west-2"
}

terraform {
  required_version = "~> 0.11"

  backend "s3" {
    bucket = "discourse-state-783633885093"
    key    = "state/terraform.tfstate"
    region = "us-west-2"
  }
}
