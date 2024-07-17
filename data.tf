data "aws_region" "current" {}
data "aws_vpc" "default" {}

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
  name = "default"
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}
