resource "aws_launch_template" "runner" {
  provider = aws.osquery-dev

  name = "GitHubRunner"

  # This will cause terraform to autoupdate the version. Which can
  # break a staging/prod seperation, but we're small.
  update_default_version  = true

  iam_instance_profile {
    arn = aws_iam_instance_profile.runner_implicit_instance_profile.arn
  }

  ebs_optimized           = "true"
  image_id                = "ami-08f2dbe31f794898b"
  key_name                = "seph-osquery-dev"

  #network_interfaces {
  #  associate_public_ip_address = true
  #  delete_on_termination = true
  #}

  # subnet_id = module.vpc.module.vpc[0].arn

  vpc_security_group_ids  = [
    module.vpc.default_security_group_id
  ]

  instance_type           = "r6g.large"
  instance_market_options {
    market_type = "spot"
  }
}


resource "aws_launch_template" "sephtestrunner" {
  provider = aws.osquery-dev
  name = "sephTestGitHubRunner"

  iam_instance_profile {
    arn = "arn:aws:iam::204725418487:instance-profile/OsqueryGitHubRunners"
  }
  ebs_optimized           = "false"
  image_id                = "ami-08f2dbe31f794898b"
  key_name                = "seph-osquery-dev"

  vpc_security_group_ids  = [
    "sg-0447741384aa67749",
  ]

  instance_type           = "r6g.large"
  instance_market_options {
    market_type = "spot"
  }

}
