############
# RDS Vars #
############

variable "rds_allocated_storage" {
  description = "allocated storage for rds postgres"
  type        = number
}

variable "rds_engine_version" {
  description = "engine version for rds postgres"
  type        = string
}

variable "rds_instance_class" {
  description = "instance class for rds postgres"
  type        = string
}

variable "rds_postgres_password" {
  description = "password for rds postgres"
  type        = string
}

variable "rds_postgres_username" {
  description = "username for rds postgres"
  type        = string
}

############
# ELC Vars #
############

variable "elc_cluster_id" {
  description = "cluster id for elc"
  type        = string
}

variable "elc_engine_type" {
  description = "engine type for elc"
  type        = string
}

variable "elc_node_type" {
  description = "node type for elc"
  type        = string
}

variable "elc_parameter_group_name" {
  description = "parameter group name for elc"
  type        = string
}

variable "elc_engine_version" {
  description = "engine version for elc"
  type        = string
}

variable "elc_redis_port" {
  description = "port of redis"
  type        = number
}

############
# ECR Vars #
############

variable "ecr_rails_image" {
  description = "Rails image address"
  type        = string
}

############
# ECS Vars #
############

variable "ecs_cluster_name" {
  description = "name of ECS Cluster"
  type        = string
}

variable "ecs_service_name" {
  description = "name of ECS Service"
  type        = string
}

variable "ecs_sidekiq_name" {
  description = "name of ECS Sidekiq"
  type        = string
}

variable "ecs_network_mode" {
  description = "ECS network mode"
  type        = string
}

variable "ecs_cpu_capacity" {
  description = "ECS CPU Capacity"
  type        = string
}

variable "ecs_memory_capacity" {
  description = "ECS Memory Capacity"
  type        = string
}

variable "ecs_rails_port" {
  description = "Rails App Port"
  type        = number
}

############
# ALB Vars #
############

variable "api_target_group_name" {
  description = "ALB Target Group name"
  type        = string
}

variable "api_target_group_port" {
  description = "ALB Target Group port for API"
  type        = number
}

variable "alb_name" {
  description = "ALB Name"
  type        = string
}

variable "alb_type" {
  description = "ALB Type"
  type        = string
}

############
# SG  Vars #
############

variable "ecs_cidr_rules" {
  description = "list of ingress rules for ecs security group. CIDR only"
  type        = list(any)
}