resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_3" {
  subnet_id      = aws_subnet.public_3.id
  route_table_id = aws_route_table.public.id
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = {
    Name = "rails-api"
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet"
  subnet_ids = [aws_subnet.public_1.id, aws_subnet.public_2.id, aws_subnet.public_3.id]
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "elc-subnet"
  subnet_ids = [aws_subnet.public_1.id, aws_subnet.public_2.id, aws_subnet.public_3.id]
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region_name}a"
  map_public_ip_on_launch = true
  tags                    = {
    Name = "pub1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "${var.aws_region_name}b"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  tags                    = {
    Name = "pub2"
  }
}

resource "aws_subnet" "public_3" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "${var.aws_region_name}c"
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true
  tags                    = {
    Name = "pub3"
  }
}