##############
# Static SG  #
##############

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port    = 5432
    to_port      = 5432
    protocol     = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "elasticache_sg" {
  name        = "elasticache-sg"
  description = "Security group for ElastiCache cluster"
  vpc_id      = var.vpc_id

  ingress {
    description      = "Redis"
    from_port        = 6379
    to_port          = 6379
    protocol         = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description  = "Allow all outbound traffic"
    from_port    = 6379
    to_port      = 6379
    protocol     = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
  }
}

###############
# Dynamic SG  #
###############

resource "aws_security_group" "ecs" {
  count  = 1
  vpc_id = var.vpc_id
  name   = "ecs"

  tags = {
    "Section"  = "Security",
    "Resource" = "sg"
  }
}

resource "aws_security_group" "alb" {
  count  = 1
  vpc_id = var.vpc_id
  name   = "alb"

  tags = {
    "Section"  = "Security",
    "Resource" = "sg"
  }
}

############
# SG Rules #
############

resource "aws_security_group_rule" "ecs_cidr" {
  count             = length(var.ecs_cidr_rules)
  description       = element(var.ecs_cidr_rules, count.index)["description"] #"Rules to allow inbound traffic for ecs by port for cidr"
  type              = element(var.ecs_cidr_rules, count.index)["type"]
  protocol          = element(var.ecs_cidr_rules, count.index)["protocol"]
  from_port         = element(var.ecs_cidr_rules, count.index)["port"]
  to_port           = element(var.ecs_cidr_rules, count.index)["port"]
  cidr_blocks       = element(var.ecs_cidr_rules, count.index)["cidr_blocks"]
  security_group_id = aws_security_group.ecs[0].id
}

resource "aws_security_group_rule" "alb_cidr" {
  count             = length(var.alb_cidr_rules)
  description       = element(var.alb_cidr_rules, count.index)["description"] #"Rules to allow inbound traffic for alb by port for cidr"
  type              = element(var.alb_cidr_rules, count.index)["type"]
  protocol          = element(var.alb_cidr_rules, count.index)["protocol"]
  from_port         = element(var.alb_cidr_rules, count.index)["port"]
  to_port           = element(var.alb_cidr_rules, count.index)["port"]
  cidr_blocks       = element(var.alb_cidr_rules, count.index)["cidr_blocks"]
  security_group_id = aws_security_group.alb[0].id
}