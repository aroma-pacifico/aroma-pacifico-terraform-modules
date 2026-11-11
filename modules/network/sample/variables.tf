variable "client" {
  description = "Synthetic client value."
  type        = string
}

variable "collection_center_cidr_blocks" {
  description = "Collection center blocks that the VPC must not overlap."
  type        = map(string)
}

variable "environment" {
  description = "Environment code: dev, qa or pdn."
  type        = string
}

variable "project" {
  description = "Synthetic project value."
  type        = string
}

variable "region" {
  description = "AWS Region of the provider configuration."
  type        = string
}

variable "subnets" {
  description = "Subnet CIDR blocks keyed by tier and Availability Zone slot."
  type        = map(map(string))
}

variable "vpc_cidr_block" {
  description = "Primary IPv4 CIDR block of the environment VPC."
  type        = string
}
