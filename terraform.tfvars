############
# RDS Vars #
############

rds_allocated_storage = 10

rds_engine_version = "13"

rds_instance_class = "db.t3.micro"

rds_postgres_password = "postgres"

rds_postgres_username = "postgres"

############
# ELC Vars #
############

elc_cluster_id = "test"

elc_engine_type = "redis"

elc_node_type = "cache.t3.micro"

elc_parameter_group_name = "default.redis7"

elc_engine_version = "7.0"

elc_redis_port = 6379

############
# ECR Vars #
############

ecr_rails_image = "381491891122.dkr.ecr.eu-north-1.amazonaws.com/test-aws:latest"

############
# ECS Vars #
############

ecs_cluster_name = "RailsCluster"

ecs_service_name = "rails-api"

ecs_sidekiq_name = "sidekiq"

ecs_network_mode = "awsvpc"

ecs_cpu_capacity = "512"

ecs_memory_capacity = "1024"

ecs_rails_port = 3000

############
# ALB Vars #
############

api_target_group_name = "rails-api-tg"

api_target_group_port = 80

alb_name = "ALBRailsAPI"

alb_type = "application"



