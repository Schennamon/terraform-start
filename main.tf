#############
#    VPC    #
#############

module "vpc" {
  source          = "./modules/vpc"
  aws_region_name = data.aws_region.current.name
}

#############
# SecGroups #
#############

module "sec_groups" {
  source          = "./modules/security_groups"
  vpc_id          = module.vpc.vpc_id
  ecs_cidr_rules  = var.ecs_cidr_rules
  alb_cidr_rules  = var.alb_cidr_rules
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
  db_subnet_group_name   = module.vpc.rds_group_name
  vpc_security_group_ids = [module.sec_groups.rds_sg_id]
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
  security_group_ids        = [module.sec_groups.elc_sg_id]
  num_cache_nodes           = "1"
  subnet_group_name         = module.vpc.elc_group_name
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
    subnets          = [module.vpc.pub_sub, module.vpc.pub_sub2, module.vpc.pub_sub3]
    security_groups  = [module.sec_groups.ecs_sg_id]
    assign_public_ip = false
  }
}

#############
#    ALB    #
#############

resource "aws_alb_target_group" "api" {
  vpc_id      = module.vpc.vpc_id
  name        = var.api_target_group_name
  port        = var.api_target_group_port
  protocol    = "HTTP"
  target_type = "ip"
}

resource "aws_lb" "application" {
  name                       = var.alb_name
  load_balancer_type         = var.alb_type
  subnets                    = [module.vpc.pub_sub, module.vpc.pub_sub2, module.vpc.pub_sub3]
  security_groups            = [module.sec_groups.alb_sg_id]
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
