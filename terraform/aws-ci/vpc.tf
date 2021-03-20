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
	from_port   = 0
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

  # TODO
  private_dedicated_network_acl     = false


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
