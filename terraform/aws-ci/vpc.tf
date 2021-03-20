resource "aws_vpc" "runners" {
  provider = aws.osquery-dev
  cidr_block = var.vpc_cidr
  tags = {
    Name = "runners"
  }

}
