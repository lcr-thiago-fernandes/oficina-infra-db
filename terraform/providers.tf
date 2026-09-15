# Sem credenciais no codigo: ambiente local (aws configure) ou OIDC no CI (role oficina-gha-infra).
provider "aws" {
  region = var.region

  default_tags {
    tags = local.tags
  }
}
