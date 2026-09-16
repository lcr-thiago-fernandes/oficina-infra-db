# Contratos deste repositório com os demais

Complementa `oficina-app/docs/contratos-entre-repositorios.md` (seções 2, 3, 6a, 6b, 6c),
`oficina-lambda-auth/docs/contratos.md` e `oficina-infra-k8s/docs/contratos.md`. Cada item falha
em silêncio se divergir; o job `contratos` do CI (`scripts/verificar-contratos.sh`) confere os
que dá para conferir por grep.

## O que este repositório LÊ (SSM Parameter Store, publicado pelo `oficina-infra-k8s`)

| Parâmetro | Tipo | Uso aqui |
|---|---|---|
| `/oficina/network/vpc_id` | String | `vpc_id` do security group do RDS |
| `/oficina/network/private_subnet_ids` | **StringList** | subnets do DB subnet group (`split(",")`) |
| `/oficina/network/eks_node_sg_id` | String | origem da regra `5432 ← sg-nodes` |

Lidos por `insecure_value` (D4). Se um deles não existir (infra-k8s ainda não aplicado), o
`plan` falha no data source com o nome do parâmetro — comportamento esperado (D9). A descoberta
é pelo SSM, **não por tag** como o design previa (D1).

## O que este repositório PUBLICA (SSM Parameter Store)

| Parâmetro | Tipo | Valor | Quem lê |
|---|---|---|---|
| `/oficina/db/endpoint` | String | **só o hostname** (`aws_db_instance.address`, sem `:porta`) | CD do oficina-app (`Host=`), oficina-auth-api (`Banco__Host`) |
| `/oficina/db/security_group_id` | String | id de `oficina-rds-sg` | oficina-lambda-auth (acrescenta `5432 ← sg-lambda-auth`) |

A porta (`5432`) é configurada à parte pelos consumidores; nunca vai embutida no endpoint.

## O que este repositório CRIA no Secrets Manager (texto puro, nunca JSON)

| Segredo | Origem do valor | Observação |
|---|---|---|
| `oficina/db_password` | `random_password` (32 chars alfanuméricos) no `apply` | `recovery_window_in_days = 0`; lido com `--query SecretString --output text` pelo CD do oficina-app e pela oficina-auth-api. Sem caracteres especiais porque o CD do oficina-app concatena `Password=${DB_PASSWORD}` sem aspas (D2). |

Não existe GitHub Secret `DB_PASSWORD` em nenhum repositório.

## Security group do RDS — compartilhado entre dois states

`oficina-rds-sg` é criado aqui **sem nenhuma regra inline** (nem `ingress = []`). As regras são
recursos separados:

| Regra | Declarada em | Recurso |
|---|---|---|
| `5432 ← sg-nodes` (EKS) | **este repo** | `aws_vpc_security_group_ingress_rule.rds_recebe_dos_nos` |
| `5432 ← sg-lambda-auth` | oficina-lambda-auth | `aws_vpc_security_group_ingress_rule.rds_recebe_da_lambda` |
| egress all | **este repo** | `aws_vpc_security_group_egress_rule.rds_saida` |

Qualquer bloco `ingress {}`/`egress {}` inline em `aws_security_group.rds` faria cada `apply`
daqui apagar a regra da Lambda (e vice-versa). O job `contratos` reprova.

## Banco — o que os consumidores assumem

| Item | Valor | Fixado por |
|---|---|---|
| Engine | PostgreSQL 16 (major; minor escolhida pelo RDS, D6) | design |
| Database | `oficina` | oficina-app (CD), oficina-lambda-auth |
| Usuário master | `oficina_admin` | oficina-app (CD), oficina-lambda-auth |
| Porta | `5432` | oficina-app (CD) |
| `rds.force_ssl` | default do RDS (`1` em PG ≥ 15), **não alterado** (D7) | oficina-auth-api usa `SSL Mode=Prefer`; Npgsql do oficina-app idem por default |
| Schemas/tabelas (`clientes.cliente`, `auth.usuario`, `os.*`) | criados pelas migrations do oficina-app | oficina-app |

## Backend e CD

| Item | Valor |
|---|---|
| State | `s3://oficina-tfstate-fiap-15soat/infra-db/terraform.tfstate`, `use_lockfile` + `oficina-tfstate-lock` |
| Role OIDC | `oficina-gha-infra` (criada por `oficina-infra-k8s/scripts/bootstrap.sh`; trust já inclui `oficina-infra-db` em `main` e `develop`) → secret `AWS_TERRAFORM_ROLE_ARN` |
| CD | `develop → plan`, `main → apply`; falha até o infra-k8s ser aplicado (D9) |
| Branch protection | `scripts/setup-branch-protection.sh` com contexts `terraform`, `scripts`, `contratos` |

## O que este repositório EXIGE dos demais

| Repo | Item |
|---|---|
| oficina-infra-k8s | Publicar os três parâmetros `/oficina/network/*` acima; aplicar **antes** deste repo; a VPC ter ≥ 2 subnets privadas em AZs distintas (DB subnet group exige) |
| oficina-lambda-auth | Declarar a regra no SG do RDS como `aws_vpc_security_group_ingress_rule` (nunca inline); ler `/oficina/db/endpoint` como hostname puro; aplicar **depois** deste repo |
| oficina-app | Connection string com `Username=oficina_admin;Database=oficina;Port=5432`; migrations criam os schemas |
