# See https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Security.html

locals {
  network_acls = {
    public_inbound = [
      {
	rule_number = 120
	rule_action = "allow"
	from_port   = 22
	to_port     = 22
	protocol    = "tcp"
	cidr_block  = "24.61.10.2/32" # seph's house
      },
    ]
    public_outbound = [
      # the port range here appears to be the _destination_ port. Not
      # the source port. eg: no real way to lock this down to packet
      # replies.
      {
	rule_number = 120
	rule_action = "allow"
	from_port   = 1024
	to_port     = 65535
	protocol    = "tcp"
	cidr_block  = "24.61.10.2/32" # seph's house
      },
    ]
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "GitHubRunners"

  cidr = "10.83.0.0/16"

  azs             = ["us-east-1a"]
  private_subnets = ["10.83.1.0/24"]
  public_subnets  = ["10.83.101.0/24"]

  public_dedicated_network_acl = true
  public_inbound_acl_rules  = local.network_acls["public_inbound"]
  public_outbound_acl_rules = local.network_acls["public_outbound"]

  manage_default_network_acl = true

  # TODO
  private_dedicated_network_acl     = false

  # FIXME: I can't get this to work
  enable_sts_endpoint = true
  sts_endpoint_security_group_ids = [data.aws_security_group.default.id]
  sts_endpoint_subnet_ids = module.vpc.public_subnets
  #sts_endpoint_private_dns_enabled = true

  enable_public_s3_endpoint = true

  enable_nat_gateway = false
  enable_vpn_gateway = false
  create_database_subnet_group = false
  create_elasticache_subnet_group = false
  create_redshift_subnet_group = false

  providers = {
    aws = aws.osquery-dev
  }

}

# I'm not totally sure why we need these. It seems to be a
# self-referencial loop. But, the docs for this module suggest it, and
# it's probably to avoid a weird race in creation ordering.
data "aws_security_group" "default" {
  provider = aws.osquery-dev
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

#data "aws_subnet" "vpc-public" {
#  provider = aws.osquery-dev
#  name   = "public_subnets"
#  vpc_id = module.vpc.vpc_id
#}
