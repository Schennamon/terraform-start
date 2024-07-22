#############
#    VPC    #
#############

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
  availability_zone       = "${data.aws_region.current.name}a"
  map_public_ip_on_launch = true
  tags                    = {
    Name = "pub1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "${data.aws_region.current.name}b"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  tags                    = {
    Name = "pub2"
  }
}

resource "aws_subnet" "public_3" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "${data.aws_region.current.name}c"
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true
  tags                    = {
    Name = "pub3"
  }
}

##############
# Static SG  #
##############

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.main.id

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
  vpc_id      = aws_vpc.main.id

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
  vpc_id = aws_vpc.main.id
  name   = "ecs"

  tags = {
    "Section"  = "Security",
    "Resource" = "sg"
  }
}

resource "aws_security_group" "alb" {
  count  = 1
  vpc_id = aws_vpc.main.id
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

#############
#    RDS    #
#############

resource "random_string" "user" {
  length  = 16
  special = false
  numeric = false
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_instance" "postgres" {
  engine                 = "postgres"
  port                   = "5432"
  allocated_storage      = var.rds_allocated_storage
  engine_version         = var.rds_engine_version
  instance_class         = var.rds_instance_class
  username               = random_string.user.result
  password               = random_password.password.result
  availability_zone      = "${data.aws_region.current.name}b"
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  multi_az               = false
  tags = {
    "Section"  = "data_store",
    "Resource" = "rds-instance"
  }
}

#############
#    ELC    #
#############

resource "aws_elasticache_cluster" "redis" {
  apply_immediately         = true
  cluster_id                = var.elc_cluster_id
  engine                    = var.elc_engine_type
  node_type                 = var.elc_node_type
  parameter_group_name      = var.elc_parameter_group_name
  engine_version            = var.elc_engine_version
  port                      = var.elc_redis_port
  security_group_ids        = [aws_security_group.elasticache_sg.id]
  num_cache_nodes           = "1"
  subnet_group_name         = aws_elasticache_subnet_group.this.name
  tags = {
    "Section"  = "Data-store",
    "Resource" = "Elasticache_cluster_redis"
  }
}

#############
#    ECS    #
#############

resource "aws_ecs_task_definition" "rails_api" {
  requires_compatibilities = ["FARGATE"]
  family                   = var.ecs_service_name
  network_mode             = var.ecs_network_mode
  cpu                      = var.ecs_cpu_capacity
  memory                   = var.ecs_memory_capacity
  execution_role_arn       = "arn:aws:iam::381491891122:role/ecsTaskExecutionRole"

  container_definitions = templatefile("./templates/container_definitions.json.tftpl",
    {
      api_container_name     = var.ecs_service_name,
      sidekiq_container_name = var.ecs_sidekiq_name
      task_image             = var.ecr_rails_image,
      rails_port             = var.ecs_rails_port,
      db_host                = aws_db_instance.postgres.address,
      db_username            = random_string.user.result,
      db_password            = random_password.password.result,
      redis_url              = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:${var.elc_redis_port}",
      redis_port             = var.elc_redis_port,
    }
  )

  depends_on = [aws_db_instance.postgres, aws_elasticache_cluster.redis]
}

resource "aws_ecs_cluster" "rails_cluster" {
  name = var.ecs_cluster_name
}

resource "aws_ecs_service" "rails_api" {
  force_new_deployment = true
  desired_count        = 1
  name                 = "RailsApi"
  launch_type          = "FARGATE"
  propagate_tags       = "SERVICE"
  cluster              = aws_ecs_cluster.rails_cluster.id
  task_definition      = aws_ecs_task_definition.rails_api.arn
  depends_on           = [aws_ecs_task_definition.rails_api]

  load_balancer {
    target_group_arn = aws_alb_target_group.api.arn
    container_name   = var.ecs_service_name
    container_port   = var.ecs_rails_port
  }

  network_configuration {
    subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id, aws_subnet.public_3.id]
    security_groups  = [aws_security_group.ecs[0].id]
    assign_public_ip = false
  }
}

#############
#    ALB    #
#############

resource "aws_alb_target_group" "api" {
  vpc_id      = aws_vpc.main.id
  name        = var.api_target_group_name
  port        = var.api_target_group_port
  protocol    = "HTTP"
  target_type = "ip"
}

resource "aws_lb" "application" {
  name                       = var.alb_name
  load_balancer_type         = var.alb_type
  subnets                    = [aws_subnet.public_1.id, aws_subnet.public_2.id, aws_subnet.public_3.id]
  security_groups            = [aws_security_group.alb[0].id]
  internal                   = false
  drop_invalid_header_fields = true
  desync_mitigation_mode     = "defensive"
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.application.arn
  protocol          = "HTTP"
  port              = var.api_target_group_port

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.api.arn
  }

  depends_on = [aws_lb.application]

  tags = {
    "Section"  = "Networking",
    "Resource" = "Listener"
  }
}
