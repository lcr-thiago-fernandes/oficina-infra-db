output "db_endpoint" {
  description = "Hostname do RDS (sem porta) — o mesmo publicado em /oficina/db/endpoint."
  value       = aws_db_instance.oficina.address
}

output "db_port" {
  value = aws_db_instance.oficina.port
}

output "db_name" {
  value = aws_db_instance.oficina.db_name
}

output "db_username" {
  value = aws_db_instance.oficina.username
}

output "db_engine_version_actual" {
  description = "Minor efetivamente provisionada (engine_version so fixa a major)."
  value       = aws_db_instance.oficina.engine_version_actual
}

output "db_security_group_id" {
  description = "SG do RDS — o mesmo publicado em /oficina/db/security_group_id."
  value       = aws_security_group.rds.id
}

output "db_parameter_group_name" {
  value = aws_db_parameter_group.postgres.name
}

output "db_password_secret_name" {
  description = "Nome do segredo com a senha (texto puro). A senha nunca sai como output."
  value       = aws_secretsmanager_secret.db_password.name
}

output "comando_obter_senha" {
  description = "Como um operador com acesso ao Secrets Manager le a senha."
  value       = "aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.db_password.name} --query SecretString --output text --region ${var.region}"
}
