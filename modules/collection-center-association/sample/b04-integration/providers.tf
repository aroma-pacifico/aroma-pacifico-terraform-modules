# Native tests replace this provider with a mock. The sample is not a deployable root: the real
# root stacks add assume_role (PC-IAC-005) and live in aroma-pacifico-infrastructure.
provider "aws" {
  alias  = "principal"
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}

provider "aws" {
  alias               = "network"
  region              = var.region
  allowed_account_ids = [format("%012d", 1)]
}
