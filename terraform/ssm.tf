# Contrato entre repositorios (RFC-004): identificadores no SSM, nunca terraform_remote_state.
# Nomes EXATOS lidos por oficina-lambda-auth (SG) e pelo CD do oficina-app (endpoint).

resource "aws_ssm_parameter" "db_security_group_id" {
  name        = "/${var.project}/db/security_group_id"
  description = "SG do RDS. O oficina-lambda-auth acrescenta nele a regra 5432 <- sg-lambda-auth."
  type        = "String"
  value       = aws_security_group.rds.id
}
