data "terraform_remote_state" "deploy" {
  backend = "s3"

  config {
    bucket = "itsre-state-783633885093"
    key    = "terraform/deploy.tfstate"
    region = "eu-west-1"
  }
}
