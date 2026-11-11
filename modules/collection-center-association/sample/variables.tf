variable "network" {
  description = "Synthetic B04-shaped output contract; existence and AZ ownership are not proven."
  type        = object({ environment = string, account_id = string, vpc_id = string, vpc_cidr_block = string, transit_attachment_subnet_ids = list(string) })
}
variable "hub" {
  description = "Synthetic hub and certificate references used only with mock providers."
  type        = object({ account_id = string, region = string, transit_gateway_id = string, customer_certificate_arn = string })
}
variable "center" {
  description = "Synthetic selected-center contract."
  type        = object({ key = string, cidr_block = string })
}
