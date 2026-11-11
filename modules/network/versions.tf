# Compatibility floor; consuming roots own provider pins and lock files.
terraform {
  required_version = ">= 1.14.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 6.0.0"
      configuration_aliases = [aws.project]
    }
  }
}
