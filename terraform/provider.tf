provider "aws" {
  region = "us-west-2"
}

provider "aws" {
  # Needed for Cloudfront SSL cert
  region = "us-east-1"
  alias  = "us-east-1"
}

terraform {
  required_version = "~> 0.12"

  backend "s3" {
    bucket = "discourse-state-783633885093"
    key    = "state/terraform.tfstate"
    region = "us-west-2"
  }
}

