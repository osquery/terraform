# common.tfvars
#
# Shared variables between the terraform stacks? workspaces?
# Whatevers. Configured by symlinking.
locals {

  remote_state_bucket = "osquery-terraform-state"

  logging_bucket = "osquery-logging"

  main_region = "us-east-1"

  aws_account_ids = {
    org:      "032511868142",
    identity: "834249036484",
    logs:     "072219116274",
    infra:    "107349553668",
    storage:  "680817131363",
    dev:      "204725418487",
  }
}
