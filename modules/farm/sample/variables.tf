variable "client" {
  description = "Example root client value."
  type        = string
  validation {
    condition     = trimspace(var.client) != ""
    error_message = "Client must not be blank."
  }
}

variable "environment" {
  description = "Offline example environment, limited to dev or qa."
  type        = string
  validation {
    condition     = contains(["dev", "qa"], var.environment)
    error_message = "The offline sample accepts dev or qa only."
  }
}

variable "farm_id" {
  description = "Synthetic opaque farm identifier, never real farm/person data."
  type        = string
  validation {
    condition     = trimspace(var.farm_id) != ""
    error_message = "Farm identifier must not be blank."
  }
}

variable "farm_key" {
  description = "Short root naming key, separate from the opaque platform identifier."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.farm_key))
    error_message = "Use a lowercase kebab naming key."
  }
}

variable "ingestion" {
  description = "Synthetic ingestion references; the child validates their detailed contract."
  type = object({
    environment = string, endpoint = string, policy_name = string, topic_template = string
  })
  validation {
    condition     = var.ingestion.environment == var.environment
    error_message = "Ingestion must belong to this example environment."
  }
}

variable "node_csr_paths" {
  description = "Paths relative to sample/ for the two public test CSR fixtures."
  type        = map(string)
  validation {
    condition     = toset(keys(var.node_csr_paths)) == toset(["crop", "drying"])
    error_message = "Exactly crop and drying CSR paths are required."
  }
}

variable "plan_role_arn" {
  description = "Empty mock-only fixture placeholder; a real account plan is outside this sample."
  type        = string
  validation {
    condition     = var.plan_role_arn == "" || can(regex("^arn:aws:iam::[0-9]{12}:role/.+$", var.plan_role_arn))
    error_message = "Use the empty mock fixture placeholder or an externally supplied role reference."
  }
}

variable "project" {
  description = "Example root project value."
  type        = string
  validation {
    condition     = trimspace(var.project) != ""
    error_message = "Project must not be blank."
  }
}

variable "region" {
  description = "Primary Region fixed by ADR-001."
  type        = string
  validation {
    condition     = var.region == "us-east-1"
    error_message = "The project sample uses the approved us-east-1 Region."
  }
}
