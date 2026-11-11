# Synthetic fixtures. The CIDR blocks are the pdn values of the addressing plan (section 4.3);
# client and project are placeholders, and no account, hostname or real address is supplied.
client      = "fx"
project     = "cf"
environment = "pdn"
region      = "us-east-1"

vpc_cidr_block = "10.82.0.0/16"

subnets = {
  public_query         = { az1 = "10.82.0.0/22", az2 = "10.82.4.0/22", az3 = "10.82.8.0/22" }
  telemetry_ingress    = { az1 = "10.82.16.0/22", az2 = "10.82.20.0/22", az3 = "10.82.24.0/22" }
  drone_object_ingress = { az1 = "10.82.32.0/22", az2 = "10.82.36.0/22", az3 = "10.82.40.0/22" }
  application          = { az1 = "10.82.48.0/22", az2 = "10.82.52.0/22", az3 = "10.82.56.0/22" }
  data                 = { az1 = "10.82.64.0/22", az2 = "10.82.68.0/22", az3 = "10.82.72.0/22" }
  object_storage       = { az1 = "10.82.80.0/22", az2 = "10.82.84.0/22", az3 = "10.82.88.0/22" }
  administration       = { az1 = "10.82.96.0/22", az2 = "10.82.100.0/22", az3 = "10.82.104.0/22" }
  transit              = { az1 = "10.82.240.0/28", az2 = "10.82.240.16/28", az3 = "10.82.240.32/28" }
}

collection_center_cidr_blocks = {
  cauca  = "10.41.0.0/16"
  huila  = "10.42.0.0/16"
  tolima = "10.43.0.0/16"
}

collection_center_summary_cidr_block = "10.40.0.0/13"
transit_gateway_id                   = "tgw-0123456789abcdef0"

# Firewall and ground station hosts follow the case statement inventory (zone 20 host .1 and zone 2 host .10).
collection_center_firewall_cidr_blocks = {
  cauca  = "10.41.20.1/32"
  huila  = "10.42.20.1/32"
  tolima = "10.43.20.1/32"
}

collection_center_ground_station_cidr_blocks = {
  cauca  = "10.41.2.10/32"
  huila  = "10.42.2.10/32"
  tolima = "10.43.2.10/32"
}

# Fixture only: the real data store port is selected by the data design (A13).
data_store_ports = [5432]

# Synthetic organization ID: the real value is supplied by the root stack and never committed here.
organization_id = "o-a1b2c3d4e5"

# Service suffixes follow the firewall policy rows CL-APP-01, CL-DRN-01 and CL-ADM-02.
# cognito-idp is UNVERIFIED: it is not listed on the AWS PrivateLink services page read on 2026-11-10,
# so confirm interface endpoint support (PD-120, PD-200) before relying on it.
interface_endpoints = {
  cogn  = { service = "cognito-idp", tier = "application" }
  exapi = { service = "execute-api", tier = "application" }
  s3    = { service = "s3", tier = "object_storage" }
  logs  = { service = "logs", tier = "administration" }
  mon   = { service = "monitoring", tier = "administration" }
  rola  = { service = "rolesanywhere", tier = "administration" }
}
