provider "aws" {
  alias               = "principal"
  region              = var.hub.region
  allowed_account_ids = [var.network.account_id]
}

# The hub account is not asserted here: the Floci emulator answers with a single account, and
# real roots add allowed_account_ids and assume_role for the network account (PC-IAC-005).
provider "aws" {
  alias  = "network"
  region = var.hub.region
}
