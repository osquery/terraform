terraform {
  required_version = "0.13.0"

  # When bootstrapping this, you will have to manually disable this and set the bucket up first.
  backend "s3" {
    bucket         = "osquery-foundation-terraform-state"
    region         = "us-east-1"
    key            = "tf/osquery/aws/backend.tfstate"
    role_arn       = "arn:aws:iam::TBD:role/osquery_tfdeployer"
    dynamodb_table = "osquery-foundation-terraform-lock"
  }
}

provider "aws" {
  allowed_account_ids = ["11112223333"]
  assume_role {
    role_arn = "arn:aws:iam::111122223333:role/osquery_tfdeployer"
  }
  region = "us-east-1"
}