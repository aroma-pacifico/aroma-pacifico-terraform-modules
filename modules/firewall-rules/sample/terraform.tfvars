# Synthetic values only: this repository is public. Center blocks follow the addressing pattern of the
# case statement (second octet 41, 42, 43); the VPC ID is a placeholder, not a real identifier.
client      = "fx"
project     = "cf"
environment = "pdn"
region      = "us-east-1"
vpc_id      = "vpc-0a1a1a1a1a1a1a1a1"
waf_scope   = "CLOUDFRONT"

collection_centers = {
  cauca = {
    device_management_cidr_blocks = ["10.41.10.0/27", "10.41.10.32/28", "10.41.10.48/31"]
    firewall_cidr_block           = "10.41.20.1/32"
    ground_station_cidr_block     = "10.41.2.10/32"
    guest_cidr_blocks             = ["10.41.4.0/24", "10.41.5.0/24"]
    logistics_cidr_block          = "10.41.3.0/24"
    staff_cidr_blocks             = ["10.41.1.0/24", "10.41.2.0/24"]
  }
  huila = {
    device_management_cidr_blocks = ["10.42.10.0/27", "10.42.10.32/28", "10.42.10.48/31"]
    firewall_cidr_block           = "10.42.20.1/32"
    ground_station_cidr_block     = "10.42.2.10/32"
    guest_cidr_blocks             = ["10.42.4.0/24", "10.42.5.0/24"]
    logistics_cidr_block          = "10.42.3.0/24"
    staff_cidr_blocks             = ["10.42.1.0/24", "10.42.2.0/24"]
  }
  tolima = {
    device_management_cidr_blocks = ["10.43.10.0/27", "10.43.10.32/28", "10.43.10.48/31"]
    firewall_cidr_block           = "10.43.20.1/32"
    ground_station_cidr_block     = "10.43.2.10/32"
    guest_cidr_blocks             = ["10.43.4.0/24", "10.43.5.0/24"]
    logistics_cidr_block          = "10.43.3.0/24"
    staff_cidr_blocks             = ["10.43.1.0/24", "10.43.2.0/24"]
  }
}

application_cidr_blocks = ["10.82.48.0/22", "10.82.52.0/22", "10.82.56.0/22"]
data_store_ports        = [5432]

lookup_allowed_path_prefixes = ["/assets/", "/s/"]
lookup_rate_scope_path       = "/s/"
lookup_rate_limit            = 100
api_rate_limit               = 2000
