terraform {
  required_version = "0.14.8"

  # When bootstrapping this, you will have to manually disable this and set the bucket up first.
  backend "s3" {
    bucket         = "osquery-terraform-state"
    region         = "us-east-1"
    key            = "tf/osquery/aws/state_bucket.tfstate"  # NOTE THIS PATH IS PROJECT SPECIFIC
    role_arn       = "arn:aws:iam::107349553668:role/IdentityAccountAccessRole"
    dynamodb_table = "osquery-terraform-state"
  }
}
