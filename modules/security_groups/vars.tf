variable "vpc_id" {}

variable "ecs_cidr_rules" {
  description = "list of ingress rules for ecs security group. CIDR only"
  type        = list(any)
}

variable "alb_cidr_rules" {
  description = "list of ingress rules for alb security group. CIDR only"
  type        = list(any)
}