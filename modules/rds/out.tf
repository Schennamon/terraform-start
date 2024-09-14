output "db_host" {
  value = aws_db_instance.postgres.address
}

output "db_user" {
  value = aws_db_instance.postgres.username
}

output "db_password" {
  sensitive = true
  value     = aws_db_instance.postgres.password
}