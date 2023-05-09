provider "aws" {
  region     = var.region
  access_key = var.access-key
  secret_key = var.secret-key
  default_tags {
    tags = local.common_tags
  }
}

