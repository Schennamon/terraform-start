output "vpc_id" {
  value = aws_vpc.main.id
}

output "rds_group_name" {
  value = aws_db_subnet_group.rds.name
}

output "elc_group_name" {
  value = aws_elasticache_subnet_group.this.name
}

output "pub_sub" {
  value = aws_subnet.public_1.id
}

output "pub_sub2" {
  value = aws_subnet.public_2.id
}

output "pub_sub3" {
  value = aws_subnet.public_3.id
}