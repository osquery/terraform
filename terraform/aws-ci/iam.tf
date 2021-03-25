# the crux of our permissions problem, is that we need to _bootstrap_
# a machine, which requires elevated permissions. And then we need to
# drop permissions, and start a runner. This is implemented using IAM
# policies. These are gated on a tag, and setup to allow a one way
# transition.
#
# So, a boot process of:
#  1. Machine starts up with an `bootstrap` tag
#  2. that tag grants access to a role
#  3. That role allows assumption of the bootstrap permissions
#  4. credentials are fetched
#  5. tag is removed
#  6. Do we need to rotate/drop our assumed credentials?
#
# References:
# https://medium.com/swlh/aws-iam-assuming-an-iam-role-from-an-ec2-instance-882081386c49
# https://aws.amazon.com/premiumsupport/knowledge-center/iam-ec2-resource-tags/
#
# Some testing snippets. These should get documented elsewhere
#
#

data "aws_iam_policy_document" "runner_implicit_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "runner_implicit_role" {
  provider = aws.osquery-dev
  name = "GitHubRunnerImplicitIamRole"
  assume_role_policy = data.aws_iam_policy_document.runner_implicit_role.json
}

# Create IAM policy to give implicit role permission to assume broad IAM Role
data "aws_iam_policy_document" "runner_role_permit_sts_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    resources = [ aws_iam_role.runner_bootstrap.arn ]
  }
}

resource "aws_iam_policy" "runner_role_permit_sts_assume" {
  provider = aws.osquery-dev
  name = "GitHubRunnerPolicyPermitStsAssume"
  policy = data.aws_iam_policy_document.runner_role_permit_sts_assume.json
}

resource "aws_iam_role_policy_attachment" "runner_attach_implicit_role_to_sts_assume_policy" {
  provider = aws.osquery-dev
  role       = aws_iam_role.runner_implicit_role.name
  policy_arn = aws_iam_policy.runner_role_permit_sts_assume.arn
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_instance_profile" "runner_implicit_instance_profile" {
  provider = aws.osquery-dev
  name = "GitHubRunnerImplicitIamRole"
  role = aws_iam_role.runner_implicit_role.name
}

##
## Policies used in bootstrapping
##

data "aws_iam_policy_document" "runner_secret_reader" {
  statement {
    actions   = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:ListSecretVersionIds",
    ]
    resources = [
      "arn:aws:secretsmanager:*:204725418487:secret:OSQUERY_GITHUB_RUNNER_TOKEN-9N6Lwh",
    ]
  }
}

resource "aws_iam_policy" "runner_secret_reader" {
  provider = aws.osquery-dev
  name = "OsqueryGitHubRunnerSecretReader"
  description = "Read access to the github runner secrets"
  policy = data.aws_iam_policy_document.runner_secret_reader.json
}


##
## Bootstrap / Initialization Role
##

data "aws_iam_policy_document" "runner_bootstrap" {
  statement {
    principals {
      type =  "AWS"
      identifiers = [aws_iam_role.runner_implicit_role.arn]
    }
    actions = [ "sts:AssumeRole" ]
  }
}

resource "aws_iam_role" "runner_bootstrap" {
  provider = aws.osquery-dev
  name = "GitHubRunnerAssumedBootstrapRole"
  assume_role_policy = data.aws_iam_policy_document.runner_bootstrap.json
  managed_policy_arns = [
    "arn:aws:iam::204725418487:policy/OsqueryGitHubRunnerSecretReader", # This was created out-of-band
  ]
}
