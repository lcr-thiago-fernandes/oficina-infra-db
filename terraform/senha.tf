# Senha gerada no apply, nunca digitada nem passada por GitHub Secret (decisao D2).
# special = false: o CD do oficina-app monta a connection string por concatenacao
# (`Password=${DB_PASSWORD}`, sem aspas) e o RDS proibe / @ " e espaco. So alfanumericos
# dispensam escape nos dois lados. 32 chars alfanumericos ~ 190 bits de entropia.
# O valor fica no state (bucket criptografado, versionado, acesso publico bloqueado).
resource "random_password" "db" {
  length      = 32
  special     = false
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
}

# TEXTO PURO, nunca JSON: o CD do oficina-app e a oficina-auth-api leem com
# `--query SecretString --output text`; um mapa JSON quebraria a autenticacao dos dois.
# recovery_window_in_days = 0: destroy imediato, senao o nome fica bloqueado por 7-30 dias
# e o proximo apply falha com "scheduled for deletion".
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.project}/db_password"
  description             = "Senha de oficina_admin no RDS oficina-postgres. Texto puro (contrato com oficina-app e oficina-lambda-auth)."
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db.result
}
