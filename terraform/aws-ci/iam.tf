# FIXME: I have IAM conditions backwards. They apply to the _target_
# not the source. As such, they are not suitable for this kind of
# scheme. Study https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-keys.html and be sad
#
# Maybe security groups???
#
# Maybe assign a specific policy?
#
# attach/replace policy?

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

# This policy lets EC2 assume this node's role
data "aws_iam_policy_document" "runner_implicit_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}


# bootstrap instance profile
resource "aws_iam_role" "runner_implicit_role" {
  provider = aws.osquery-dev
  name = "GitHubRunnerImplicitIamRole"
  assume_role_policy = data.aws_iam_policy_document.runner_implicit_role.json
}

resource "aws_iam_instance_profile" "runner_implicit_instance_profile" {
  provider = aws.osquery-dev
  name = "GitHubRunnerImplicitIamRole"
  role = aws_iam_role.runner_implicit_role.name
}


# Runtime intance profile
resource "aws_iam_role" "runner_runtime_implicit_role" {
  provider = aws.osquery-dev
  name = "GitHubRunnerRuntimeImplicitIamRole"
  assume_role_policy = data.aws_iam_policy_document.runner_implicit_role.json
}

resource "aws_iam_instance_profile" "runner_runtime_implicit_role" {
  provider = aws.osquery-dev
  name = "GitHubRunnerRuntimeImplicitIamRole"
  role = aws_iam_role.runner_runtime_implicit_role.name
}



# Create IAM policy to give implicit role permission to assume broad IAM Role
# Sadly, we cannot use tags to restrict this. So say the docs (and it doesn't work)
data "aws_iam_policy_document" "runner_role_permit_sts_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    resources = [ aws_iam_role.runner_bootstrap.arn ]

    # FIXME: tag conditions here?
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

    #condition {
    #  test = "StringEquals"
    #  variable = "aws:TagKeys"
    #  values = [ "Bootstrapping" ]
    #}


  }
}

resource "aws_iam_policy" "runner_secret_reader" {
  provider = aws.osquery-dev
  name = "OsqueryGitHubRunnerSecretReader"
  description = "Read access to the github runner secrets"
  policy = data.aws_iam_policy_document.runner_secret_reader.json
}



data "aws_iam_policy_document" "ec2_instance_downgrader" {
  statement {
    actions   = [
      "ec2:ReplaceIamInstanceProfileAssociation",
      "ec2:DescribeIamInstanceProfileAssociations",
      "iam:PassRole", # Needed to scope this account to passing this role
    ]
    resources = [
      "*"
    ]

    # TODO: conditions?
    # iam:RoleName GitHubRunnerRuntimeImplicitIamRole
    # aws:Resource role/GitHubRunnerRuntimeImplicitIamRole
    #condition {
    #  test = "StringEquals"
    #  variable = "aws:TagKeys"
    #  values = [ "Bootstrapping" ]
    #}


  }
}

resource "aws_iam_policy" "ec2_instance_downgrader" {
  provider = aws.osquery-dev
  name = "GitHubRunnerInstanceDowngrader"
  description = "Permission to downgrade an instances IAM role"
  policy = data.aws_iam_policy_document.ec2_instance_downgrader.json
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

    # https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-keys.html#condition-keys-principaltag
    #condition {
    #  test = "StringEquals"
    #  variable = "aws:PrincipalTag/Bootstrapping"
    #  values = [ "true" ]
    #}
  }
}

resource "aws_iam_role" "runner_bootstrap" {
  provider = aws.osquery-dev
  name = "GitHubRunnerAssumedBootstrapRole"
  assume_role_policy = data.aws_iam_policy_document.runner_bootstrap.json
  managed_policy_arns = [
    aws_iam_policy.runner_secret_reader.arn,
    aws_iam_policy.ec2_instance_downgrader.arn,
  ]
}


##
## Runtime Permissions
##

data "aws_iam_policy_document" "runner_runtime_implicit_role" {

}
