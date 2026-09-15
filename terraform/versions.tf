# Versoes fixadas em aws 5.x, como nos outros tres repositorios (decisao D12; aws 6 muda sintaxe).
terraform {
  required_version = ">= 1.10" # use_lockfile no backend S3

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
