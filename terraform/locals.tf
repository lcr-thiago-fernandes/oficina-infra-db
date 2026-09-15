locals {
  nome_instancia    = "${var.project}-postgres"
  nome_sg           = "${var.project}-rds-sg"
  nome_subnet_group = "${var.project}-db-subnet-group"

  # "16" -> "postgres16"; "16.4" tambem -> "postgres16".
  familia_parametros = "postgres${split(".", var.db_engine_version)[0]}"
  nome_param_group   = "${var.project}-${local.familia_parametros}"

  # StringList do SSM: "subnet-a,subnet-b".
  private_subnet_ids = split(",", data.aws_ssm_parameter.private_subnet_ids.insecure_value)

  tags = {
    Project   = var.project
    ManagedBy = "Terraform"
    Repo      = "oficina-infra-db"
    Fase      = "fase-3"
  }
}
