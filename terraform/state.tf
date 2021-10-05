data "terraform_remote_state" "deploy" {
  backend = "s3"

  config = {
    bucket = "itsre-state-783633885093"
    key    = "terraform/deploy.tfstate"
    region = "eu-west-1"
  }
}

data "terraform_remote_state" "k8s" {
  backend = "s3"

  config = {
    bucket = "itse-apps-stage-1-state"
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}

