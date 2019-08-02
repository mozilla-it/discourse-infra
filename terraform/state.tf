data "terraform_remote_state" "deploy" {
  backend = "s3"

  config {
    bucket = "itsre-state-783633885093"
    key    = "terraform/deploy.tfstate"
    region = "eu-west-1"
  }
}

data "terraform_remote_state" "k8s" {
  backend = "s3"

  config {
    bucket = "itsre-state-783633885093"
    key    = "us-west-2/itsre-apps-1/terraform.tfstate"
    region = "eu-west-1"
  }
}
