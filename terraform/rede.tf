# DB subnet group nas subnets privadas do oficina-infra-k8s (RDS nunca em subnet publica).
resource "aws_db_subnet_group" "oficina" {
  name        = local.nome_subnet_group
  description = "Subnets privadas da VPC da oficina (lidas de /${var.project}/network/private_subnet_ids)"
  subnet_ids  = local.private_subnet_ids

  tags = { Name = local.nome_subnet_group }
}

# SG COMPARTILHADO entre dois states (decisao D3): este repositorio cria o SG e a regra
# 5432 <- sg-nodes; o oficina-lambda-auth acrescenta 5432 <- sg-lambda-auth aqui, a partir
# do state dele (aws_vpc_security_group_ingress_rule.rds_recebe_da_lambda).
#
# Por isso NAO existe bloco ingress/egress inline neste recurso — nem `ingress = []`.
# Omitidos por completo, o provider trata as regras como nao gerenciadas por este recurso;
# qualquer bloco inline faria cada apply daqui apagar a regra da Lambda (e vice-versa).
resource "aws_security_group" "rds" {
  name        = local.nome_sg
  description = "PostgreSQL 5432 a partir dos nos do EKS (oficina-app) e da oficina-auth-api"
  vpc_id      = data.aws_ssm_parameter.vpc_id.insecure_value

  tags = { Name = local.nome_sg }
}

resource "aws_vpc_security_group_ingress_rule" "rds_recebe_dos_nos" {
  security_group_id            = aws_security_group.rds.id
  description                  = "PostgreSQL a partir dos nos do EKS (pods do oficina-app)"
  ip_protocol                  = "tcp"
  from_port                    = var.db_port
  to_port                      = var.db_port
  referenced_security_group_id = data.aws_ssm_parameter.eks_node_sg_id.insecure_value
}

# O RDS nao inicia conexoes; a regra existe por paridade com a Fase 2 e com a tabela de SGs
# do design (sg-rds: egress all). Sem ela o SG nasce sem saida (o provider remove a default).
resource "aws_vpc_security_group_egress_rule" "rds_saida" {
  security_group_id = aws_security_group.rds.id
  description       = "Saida liberada"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
