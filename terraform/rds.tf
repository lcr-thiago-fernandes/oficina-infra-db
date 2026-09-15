# Parameter group customizado (design, "RDS — mudancas em relacao a Fase 2"):
# log_min_duration_statement e dinamico, nao exige reboot.
resource "aws_db_parameter_group" "postgres" {
  name        = local.nome_param_group
  family      = local.familia_parametros
  description = "PostgreSQL ${var.db_engine_version} da oficina: loga statements acima de ${var.db_log_min_duration_statement_ms} ms"

  parameter {
    name         = "log_min_duration_statement"
    value        = tostring(var.db_log_min_duration_statement_ms)
    apply_method = "immediate"
  }
}

# Log group com o nome que o RDS usa ao exportar `postgresql`, criado ANTES da instancia para
# fixar a retencao (decisao D5). Se o RDS o criar primeiro, ele nasce sem expiracao e este
# recurso falha com ResourceAlreadyExists — por isso o depends_on na instancia.
resource "aws_cloudwatch_log_group" "postgresql" {
  name              = "/aws/rds/instance/${local.nome_instancia}/postgresql"
  retention_in_days = var.log_retention_days
}

resource "aws_db_instance" "oficina" {
  identifier     = local.nome_instancia
  engine         = "postgres"
  engine_version = var.db_engine_version # so a major (decisao D6)
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result
  port     = var.db_port

  db_subnet_group_name   = aws_db_subnet_group.oficina.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.postgres.name

  multi_az            = false # CUSTO: single-AZ (design).
  publicly_accessible = false # NUNCA exposto na internet; acesso so pelos SGs.

  backup_retention_period = var.db_backup_retention_days
  copy_tags_to_snapshot   = true

  performance_insights_enabled          = true
  performance_insights_retention_period = var.db_performance_insights_retention_days
  enabled_cloudwatch_logs_exports       = ["postgresql"]

  auto_minor_version_upgrade = true
  apply_immediately          = var.db_apply_immediately

  # Ambiente precisa ser destruivel (design): sem snapshot final, sem protecao.
  skip_final_snapshot = true
  deletion_protection = false

  depends_on = [aws_cloudwatch_log_group.postgresql]

  tags = { Name = local.nome_instancia }
}
