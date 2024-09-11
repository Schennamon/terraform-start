output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}

output "elc_sg_id" {
  value = aws_security_group.elasticache_sg.id
}

output "alb_sg_id" {
  value = aws_security_group.alb[0].id
}

output "ecs_sg_id" {
  value = aws_security_group.ecs[0].id
}

