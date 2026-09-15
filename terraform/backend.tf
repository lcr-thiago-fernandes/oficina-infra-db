# Bucket e tabela criados por oficina-infra-k8s/scripts/bootstrap.sh (uma vez, antes do
# primeiro init de qualquer repositorio). Cada repositorio tem a propria key: nenhum le o
# state do outro (RFC-004). use_lockfile + dynamodb_table: mesmo padrao do oficina-infra-k8s.
terraform {
  backend "s3" {
    bucket         = "oficina-tfstate-fiap-15soat"
    key            = "infra-db/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "oficina-tfstate-lock"
    use_lockfile   = true
    encrypt        = true
  }
}
