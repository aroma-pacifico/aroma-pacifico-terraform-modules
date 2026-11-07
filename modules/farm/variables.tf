variable "additional_tags" {
  description = "Desired non-secret cost metadata; current IoT resource types do not support AWS tags."
  type        = map(string)
  default     = {}
  nullable    = false
  validation {
    condition     = alltrue([for key, value in var.additional_tags : trimspace(key) != "" && value != null])
    error_message = "Additional tag keys must be nonempty and values must not be null."
  }
}

variable "client" {
  description = "Root-supplied client governance value."
  type        = string
  nullable    = false
  validation {
    condition     = trimspace(var.client) != ""
    error_message = "Client must not be blank."
  }
}

variable "environment" {
  description = "Environment owning this farm's cloud identities."
  type        = string
  nullable    = false
  validation {
    condition     = contains(["dev", "qa", "pdn"], var.environment)
    error_message = "Environment must be dev, qa, or pdn."
  }
}

variable "farm_id" {
  description = "One stable, opaque platform farm identifier; no inventory or personal/location data."
  type        = string
  nullable    = false
  validation {
    condition     = trimspace(var.farm_id) != ""
    error_message = "Provide one nonblank farm identifier; no identifier format is assumed."
  }
}

variable "ingestion" {
  description = "Same-environment IoT endpoint, existing policy, and topic template from the ingestion owner."
  type = object({
    environment    = string
    endpoint       = string
    policy_name    = string
    topic_template = string
  })
  nullable = false
  validation {
    condition     = var.ingestion.environment == var.environment
    error_message = "Ingestion and farm environments must match."
  }
  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9.-]*[A-Za-z0-9]$", var.ingestion.endpoint)) && try(strcontains(var.ingestion.endpoint, "."), false)
    error_message = "Ingestion endpoint must be a DNS hostname without a URL scheme, port, or path."
  }
  validation {
    condition     = try(trimspace(var.ingestion.policy_name) != "", false)
    error_message = "An existing ingestion policy name is required."
  }
  validation {
    condition     = try(length(regexall("\\{thing_name\\}", var.ingestion.topic_template)) == 1 && !strcontains(var.ingestion.topic_template, "+") && !strcontains(var.ingestion.topic_template, "#"), false)
    error_message = "The publish topic template must contain exactly one {thing_name} and no MQTT wildcards."
  }
}

variable "name_prefix" {
  description = "Root-built governance/resource prefix; only the crop/drying suffix is appended here."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)+$", var.name_prefix)) && length(var.name_prefix) <= 21 && startswith(var.name_prefix, "${var.client}-${var.project}-${var.environment}-")
    error_message = "Use a root-built lowercase kebab prefix matching client-project-environment, at most 21 characters (28 including -drying)."
  }
}

variable "nodes" {
  description = "Exactly the crop and drying node public CSRs; private keys remain on their originating devices."
  type        = map(object({ csr = string }))
  nullable    = false
  validation {
    condition     = toset(keys(var.nodes)) == toset(["crop", "drying"])
    error_message = "One farm requires exactly crop and drying node entries."
  }
  validation {
    condition     = alltrue([for node in var.nodes : can(regex("(?s)^-----BEGIN CERTIFICATE REQUEST-----\\r?\\n[A-Za-z0-9+/=\\r\\n]+-----END CERTIFICATE REQUEST-----\\s*$", node.csr))])
    error_message = "Each node requires a public PEM certificate signing request, never a private key."
  }
  validation {
    condition     = length(distinct([for node in var.nodes : node.csr])) == length(var.nodes)
    error_message = "Crop and drying must supply distinct node CSRs."
  }
}

variable "project" {
  description = "Root-supplied project governance value."
  type        = string
  nullable    = false
  validation {
    condition     = trimspace(var.project) != ""
    error_message = "Project must not be blank."
  }
}
