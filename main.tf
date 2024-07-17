##############
# Static SG  #
##############

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = data.aws_vpc.default.id

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
  vpc_id      = data.aws_vpc.default.id

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
  vpc_id = data.aws_vpc.default.id
  name   = "ecs"

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

#############
#    RDS    #
#############

resource "aws_db_instance" "postgres" {
  engine                 = "postgres"
  port                   = "5432"
  allocated_storage      = var.rds_allocated_storage
  engine_version         = var.rds_engine_version
  instance_class         = var.rds_instance_class
  username               = var.rds_postgres_username
  password               = var.rds_postgres_password
  availability_zone      = "${data.aws_region.current.name}b"
  db_subnet_group_name   = ""
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = true
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
  subnet_group_name         = ""
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

  container_definitions = jsonencode([
    {
      name      = var.ecs_service_name
      image     = var.ecr_rails_image
      cpu       = 0
      portMappings = [
        {
          name          = "rails-${var.ecs_rails_port}-tcp"
          containerPort = var.ecs_rails_port
          hostPort      = var.ecs_rails_port
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]
      essential = true
      command   = ["./bin/rails", "server", "-b", "0.0.0.0"]
      environment = [
        {
          name  = "RAILS_ENV"
          value = "development"
        },
        {
          name  = "DB_PORT"
          value = "5432"
        },
        {
          name  = "DB_USER"
          value = var.rds_postgres_username
        },
        {
          name  = "DB_HOST"
          value = aws_db_instance.postgres.address
        },
        {
          name  = "SECRET_KEY_BASE"
          value = "83e5a992e2c1a3e4da087195fc96a9d4dad34760c1e617fd92ee25cc9640662600cf35d5fe022d3804bb29928a18738fd1778655512928d0fa2c81cf0573b7e5"
        },
        {
          name  = "DB_PASSWORD"
          value = var.rds_postgres_password
        },
        {
          name  = "REDIS_URL"
          value = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.cache_nodes[0].port}"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/test-rails-app"
          "awslogs-create-group"  = "true"
          "awslogs-region"        = "eu-north-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
    {
      name      = var.ecs_sidekiq_name
      image     = var.ecr_rails_image
      cpu       = 0
      portMappings = [
        {
          name          = "redis-${var.elc_redis_port}-tcp"
          containerPort = var.elc_redis_port
          hostPort      = var.elc_redis_port
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]
      essential = true
      command   = ["bundle", "exec", "sidekiq"]
      environment = [
        {
          name  = "RAILS_ENV"
          value = "development"
        },
        {
          name  = "DB_PORT"
          value = "5432"
        },
        {
          name  = "DB_USER"
          value = var.rds_postgres_username
        },
        {
          name  = "DB_HOST"
          value = aws_db_instance.postgres.address
        },
        {
          name  = "SECRET_KEY_BASE"
          value = "83e5a992e2c1a3e4da087195fc96a9d4dad34760c1e617fd92ee25cc9640662600cf35d5fe022d3804bb29928a18738fd1778655512928d0fa2c81cf0573b7e5"
        },
        {
          name  = "DB_PASSWORD"
          value = var.rds_postgres_password
        },
        {
          name  = "REDIS_URL"
          value = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.cache_nodes[0].port}"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/test-rails-app"
          "awslogs-create-group"  = "true"
          "awslogs-region"        = "eu-north-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

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
  depends_on           = [aws_db_instance.postgres, aws_elasticache_cluster.redis, aws_ecs_task_definition.rails_api]

  load_balancer {
    target_group_arn = aws_alb_target_group.api[0].arn
    container_name   = jsondecode(aws_ecs_task_definition.rails_api.container_definitions)[0].name
    container_port   = var.ecs_rails_port
  }

  network_configuration {
    subnets          = data.aws_subnet_ids.default.ids
    security_groups  = [aws_security_group.ecs[0].id]
    assign_public_ip = true
  }
}

#############
#    ALB    #
#############

resource "aws_alb_target_group" "api" {
  count       = 1
  vpc_id      = data.aws_vpc.default.id
  name        = var.api_target_group_name
  port        = var.api_target_group_port
  protocol    = "HTTP"
  target_type = "ip"
}

resource "aws_lb" "application" {
  name                       = var.alb_name
  load_balancer_type         = var.alb_type
  subnets                    = data.aws_subnet_ids.default.ids
  internal                   = false
  drop_invalid_header_fields = true
  desync_mitigation_mode     = "defensive"
}

resource "aws_alb_listener" "http" {
  depends_on = [
    aws_lb.application,
  ]
  load_balancer_arn = aws_lb.application.arn
  protocol          = "HTTP"
  port              = var.api_target_group_port

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.api[0].arn
  }
  tags = (merge(
    tomap({
      "Section"  = "Networking",
      "Resource" = "Listener"
    })
  ))
}
