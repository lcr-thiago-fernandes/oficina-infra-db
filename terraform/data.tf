# Contrato via SSM (RFC-004): nenhum terraform_remote_state. Publicados pelo oficina-infra-k8s
# (decisao D1). Se um parametro nao existir (infra-k8s ainda nao aplicado), o plan falha aqui,
# com o nome do parametro na mensagem — e o comportamento esperado (decisao D9).
#
# Leitura por `insecure_value` (decisao D4): o data source marca `value` como sensivel, e isso
# esconderia vpc_id, subnets e o SG de origem no plan como "(sensitive value)". Sao
# identificadores publicos, nao segredos.
data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.project}/network/vpc_id"
}

data "aws_ssm_parameter" "private_subnet_ids" {
  name = "/${var.project}/network/private_subnet_ids"
}

data "aws_ssm_parameter" "eks_node_sg_id" {
  name = "/${var.project}/network/eks_node_sg_id"
}
