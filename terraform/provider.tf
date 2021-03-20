terraform {
  required_version = "0.14.8"

  # When bootstrapping this, you will have to manually disable this and set the bucket up first.
  backend "s3" {
    bucket         = "osquery-terraform-state"
    region         = "us-east-1"
    key            = "tf/osquery/aws/state_bucket.tfstate"
    role_arn       = "arn:aws:iam::107349553668:role/IdentityAccountAccessRole"
    dynamodb_table = "osquery-terraform-state"
  }
}

# This is the default provider. It will use whatever from the environment.
provider "aws" {
  region = local.main_region

}

##
## Various targetted providers. It would be nice if this could read
## the ARNs from .config, but <shrug> this works.
##

# NOTE: durations of under 900 will cause errors

provider "aws" {
  alias = "osquery-infra"
  assume_role {
    duration_seconds = 900
    external_id = "terraform"
    role_arn = "arn:aws:iam::107349553668:role/IdentityAccountAccessRole"
  }
  region = local.main_region
}

provider "aws" {
  alias = "osquery-dev"
  assume_role {
    duration_seconds = 900
    external_id = "terraform"
    role_arn = "arn:aws:iam::204725418487:role/IdentityAccountAccessRole"
  }
  region = local.main_region
}
