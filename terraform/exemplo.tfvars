# Copie para local.tfvars (gitignored) se quiser sobrescrever defaults num apply manual.
# Nao ha valor sensivel aqui: a senha e gerada no apply (random_password).
region  = "us-east-1"
project = "oficina"

db_engine_version                      = "16"
db_instance_class                      = "db.t3.micro"
db_allocated_storage                   = 20
db_backup_retention_days               = 1
db_performance_insights_retention_days = 7
db_log_min_duration_statement_ms       = 500
db_apply_immediately                   = true
log_retention_days                     = 14
