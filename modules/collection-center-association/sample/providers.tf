provider "aws" {
  alias               = "principal"
  region              = var.hub.region
  allowed_account_ids = [var.network.account_id]
}
provider "aws" {
  alias               = "network"
  region              = var.hub.region
  allowed_account_ids = [var.hub.account_id]
}
