#!/usr/bin/env bash
# Verifica, por grep no Terraform, os contratos deste repositorio com os outros tres
# (docs/contratos.md). Um `terraform validate` verde NAO pega um nome de SSM errado,
# `.endpoint` no lugar de `.address`, nem uma regra inline no SG que apagaria a regra da Lambda.
set -euo pipefail

cd "$(dirname "$0")/.." || exit 1
TF_DIR="terraform"
falhas=0

erro() { echo "ERRO: $*" >&2; falhas=$((falhas + 1)); }
ok()   { echo "OK:   $*"; }

# 1. SSM LIDOS (publicados pelo oficina-infra-k8s) — nomes exatos.
for ssm in '/network/vpc_id' '/network/private_subnet_ids' '/network/eks_node_sg_id'; do
  if grep -n -E "name[[:space:]]*=[[:space:]]*\"/\\\$\{var\.project\}${ssm}\"" "$TF_DIR/data.tf" >/dev/null; then
    ok "le SSM /oficina${ssm}."
  else
    erro "data source de /oficina${ssm} ausente em ${TF_DIR}/data.tf."
  fi
done
if grep -n 'insecure_value' "$TF_DIR/locals.tf" "$TF_DIR/rede.tf" >/dev/null; then
  ok "data sources SSM lidos por insecure_value (decisao D4)."
else
  erro "use insecure_value nos data sources SSM (value e sensivel e esconde ids no plan)."
fi

# 2. SSM PUBLICADOS (lidos pelo oficina-lambda-auth e pelo CD do oficina-app) — nomes exatos.
for ssm in '/db/endpoint' '/db/security_group_id'; do
  if grep -n -E "name[[:space:]]*=[[:space:]]*\"/\\\$\{var\.project\}${ssm}\"" "$TF_DIR/ssm.tf" >/dev/null; then
    ok "publica SSM /oficina${ssm}."
  else
    erro "SSM /oficina${ssm} nao encontrado em ${TF_DIR}/ssm.tf."
  fi
done
# 2a. /oficina/db/endpoint e SO o hostname: .address, nunca .endpoint (que inclui :porta).
if grep -n -E 'value[[:space:]]*=[[:space:]]*aws_db_instance\.oficina\.address' "$TF_DIR/ssm.tf" >/dev/null; then
  ok "/oficina/db/endpoint usa aws_db_instance.oficina.address."
else
  erro "/oficina/db/endpoint precisa ser aws_db_instance.oficina.address (so hostname)."
fi
if grep -rn --include='*.tf' -E 'aws_db_instance\.[a-z_]+\.endpoint\b' "$TF_DIR" >/dev/null; then
  erro "aws_db_instance.*.endpoint encontrado: inclui a porta e quebra Host=/Banco__Host nos consumidores."
else
  ok "nenhum uso de aws_db_instance.*.endpoint."
fi

# 3. Segredo em texto puro, com destroy imediato.
if grep -n -E "name[[:space:]]*=[[:space:]]*\"\\\$\{var\.project\}/db_password\"" "$TF_DIR/senha.tf" >/dev/null; then
  ok "segredo oficina/db_password criado."
else
  erro "segredo oficina/db_password ausente em ${TF_DIR}/senha.tf."
fi
if grep -n -E 'recovery_window_in_days[[:space:]]*=[[:space:]]*0' "$TF_DIR/senha.tf" >/dev/null; then
  ok "recovery_window_in_days = 0."
else
  erro "oficina/db_password precisa de recovery_window_in_days = 0 (senao o nome fica bloqueado apos destroy)."
fi
if grep -rn --include='*.tf' -E 'secret_string[[:space:]]*=[[:space:]]*jsonencode' "$TF_DIR" >/dev/null; then
  erro "secret_string com jsonencode: os consumidores leem texto puro."
else
  ok "secret_string em texto puro."
fi
if grep -rn --include='*.tf' 'manage_master_user_password' "$TF_DIR" >/dev/null; then
  erro "manage_master_user_password grava JSON num segredo de nome aleatorio; o contrato e oficina/db_password em texto puro."
else
  ok "sem manage_master_user_password."
fi

# 4. Security group compartilhado com o oficina-lambda-auth: regras SEMPRE separadas.
if grep -n -E '^[[:space:]]*(ingress|egress)[[:space:]]*(\{|=)' "$TF_DIR/rede.tf" >/dev/null; then
  erro "bloco ingress/egress inline (ou = []) em aws_security_group: apagaria a regra do oficina-lambda-auth a cada apply."
else
  ok "aws_security_group sem regras inline."
fi
if grep -rn --include='*.tf' -E 'resource[[:space:]]+"aws_security_group_rule"' "$TF_DIR" >/dev/null; then
  erro "recurso legado aws_security_group_rule; use aws_vpc_security_group_ingress_rule/_egress_rule."
else
  ok "sem aws_security_group_rule legado."
fi
if grep -n -E 'referenced_security_group_id[[:space:]]*=[[:space:]]*data\.aws_ssm_parameter\.eks_node_sg_id\.insecure_value' "$TF_DIR/rede.tf" >/dev/null; then
  ok "ingress 5432 a partir de /oficina/network/eks_node_sg_id."
else
  erro "regra de ingress a partir do SG dos nos do EKS ausente."
fi

# 5. Nomes fixados pelo oficina-app (connection string do CD) e pelo oficina-lambda-auth.
checar_default() { # variavel, valor esperado (regex), rotulo
  if grep -n -A4 "variable \"$1\"" "$TF_DIR/variables.tf" | grep -E "default[[:space:]]*=[[:space:]]*$2" >/dev/null; then
    ok "$3"
  else
    erro "$3 — esperado default $2 em variable \"$1\"."
  fi
}
checar_default db_name '"oficina"' 'db_name = oficina'
checar_default db_username '"oficina_admin"' 'db_username = oficina_admin'
checar_default db_port '5432' 'db_port = 5432'
checar_default db_log_min_duration_statement_ms '500' 'log_min_duration_statement = 500'
checar_default db_engine_version '"16"' 'engine_version = 16'

# 6. Postura do RDS (design): privado, criptografado, destruivel.
checar_rds() { # atributo, valor
  if grep -n -E "$1[[:space:]]*=[[:space:]]*$2" "$TF_DIR/rds.tf" >/dev/null; then
    ok "$1 = $2"
  else
    erro "$1 precisa ser $2 em ${TF_DIR}/rds.tf."
  fi
}
checar_rds publicly_accessible false
checar_rds storage_encrypted true
checar_rds multi_az false
checar_rds skip_final_snapshot true
checar_rds deletion_protection false
checar_rds performance_insights_enabled true
if grep -n -E 'name[[:space:]]*=[[:space:]]*"log_min_duration_statement"' "$TF_DIR/rds.tf" >/dev/null; then
  ok "parameter group define log_min_duration_statement."
else
  erro "parameter log_min_duration_statement ausente no parameter group."
fi

# 7. Backend: key propria e lock.
if grep -n -E 'key[[:space:]]*=[[:space:]]*"infra-db/terraform.tfstate"' "$TF_DIR/backend.tf" >/dev/null; then
  ok "backend key infra-db/terraform.tfstate."
else
  erro "backend key precisa ser infra-db/terraform.tfstate."
fi
if grep -n -E 'use_lockfile[[:space:]]*=[[:space:]]*true' "$TF_DIR/backend.tf" >/dev/null; then
  ok "use_lockfile = true."
else
  erro "backend sem use_lockfile = true."
fi

echo
if [ "$falhas" -gt 0 ]; then
  echo "${falhas} contrato(s) violado(s)." >&2
  exit 1
fi
echo "Todos os contratos verificados."
