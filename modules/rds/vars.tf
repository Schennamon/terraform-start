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

variable "aws_region_name" {
  description = "name of aws region"
  type        = string
}

variable "subnet_group_name" {
  description = "name of rds subnet group"
  type        = string
}

variable "sg_id" {
  description = "id of security group"
  type        = string
}