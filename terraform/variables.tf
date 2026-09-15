variable "region" {
  description = "Regiao AWS (a mesma do oficina-infra-k8s: os parametros SSM sao regionais)."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Prefixo dos recursos e dos caminhos no SSM (mesmo dos outros repositorios)."
  type        = string
  default     = "oficina"
}

# --- Banco (contrato com oficina-app e oficina-lambda-auth) ---
variable "db_name" {
  description = "Nome do banco inicial. Contrato: oficina-app e oficina-auth-api conectam em 'oficina'."
  type        = string
  default     = "oficina"
}

variable "db_username" {
  description = "Usuario master. Contrato: o CD do oficina-app fixa 'oficina_admin' na connection string."
  type        = string
  default     = "oficina_admin"
}

variable "db_port" {
  description = "Porta do PostgreSQL. Contrato: os consumidores configuram 5432 a parte do hostname."
  type        = number
  default     = 5432
}

# --- Instancia ---
variable "db_engine_version" {
  description = "Versao MAJOR do PostgreSQL (decisao D6: o RDS escolhe a minor; auto_minor_version_upgrade)."
  type        = string
  default     = "16"
}

variable "db_instance_class" {
  description = "Classe da instancia."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Armazenamento em GB (gp3)."
  type        = number
  default     = 20
}

variable "db_backup_retention_days" {
  description = "Dias de retencao dos backups automaticos (design: 1)."
  type        = number
  default     = 1
}

variable "db_performance_insights_retention_days" {
  description = "Retencao do Performance Insights em dias (7 = gratuito)."
  type        = number
  default     = 7
}

variable "db_log_min_duration_statement_ms" {
  description = "Statements acima deste tempo (ms) vao para o log postgresql (design: 500)."
  type        = number
  default     = 500
}

variable "db_apply_immediately" {
  description = "Aplica modificacoes fora da janela de manutencao (ambiente de demonstracao)."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Retencao do log group /aws/rds/instance/<id>/postgresql no CloudWatch (decisao D5)."
  type        = number
  default     = 14
}
