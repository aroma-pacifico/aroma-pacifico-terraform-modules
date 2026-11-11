variable "additional_tags" {
  description = "Extra non-secret tags merged into every taggable resource."
  type        = map(string)
  default     = {}
  nullable    = false

  validation {
    condition     = alltrue([for key, value in var.additional_tags : trimspace(key) != "" && value != null])
    error_message = "Additional tag keys must be nonempty and values must not be null."
  }
}

variable "client" {
  description = "Client governance value from the root. At most 10 lowercase alphanumeric characters (PC-IAC-003)."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]{1,10}$", var.client))
    error_message = "Client must be 1 to 10 lowercase alphanumeric characters."
  }
}

variable "environment" {
  description = "Environment code: dev, qa or pdn."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["dev", "qa", "pdn"], var.environment)
    error_message = "Environment must be dev, qa or pdn."
  }
}

variable "functions" {
  description = <<-EOT
    Inference functions keyed by a short key of at most 6 lowercase alphanumeric characters (the key ends up in every physical name).
    Each entry describes one event-driven function: its package, its sizing and retry design values, the three permissions of the
    Epic 6 pattern (read the persisted object, write the result, invoke managed inference) and the services allowed to send to its queue.
    read.kms_classes and write.kms_classes name data classes of the security module (telemetry, objects or records); the records
    key is always granted for the queue, the dead-letter queue and the environment variables.
  EOT
  type = map(object({
    description     = string
    package         = object({ filename = string, source_code_hash = optional(string) })
    handler         = optional(string, "index.handler")
    runtime         = optional(string, "python3.13")
    timeout_seconds = optional(number, 300)
    memory_mb       = optional(number, 512)

    batch_size           = optional(number, 1)
    reserved_concurrency = optional(number, 5)
    max_receive_count    = optional(number, 5)
    backoff_base_seconds = optional(number, 60)

    read = optional(object({
      s3_object_arns      = optional(list(string), [])
      dynamodb_table_arns = optional(list(string), [])
      kms_classes         = optional(list(string), [])
    }), {})

    write = optional(object({
      dynamodb_table_arns = optional(list(string), [])
      sns_topic_arns      = optional(list(string), [])
      kms_classes         = optional(list(string), [])
    }), {})

    inference = object({
      model_id = string
    })

    queue_senders = optional(object({
      service_principals = optional(list(string), [])
      source_arns        = optional(list(string), [])
    }), {})

    environment_variables = optional(map(string), {})
  }))
  nullable = false

  validation {
    condition     = length(var.functions) > 0 && alltrue([for key in keys(var.functions) : can(regex("^[a-z0-9]{1,6}$", key))])
    error_message = "Declare at least one function; each key must be 1 to 6 lowercase alphanumeric characters (PC-IAC-003 28 character cap)."
  }

  validation {
    condition     = alltrue([for f in values(var.functions) : f.timeout_seconds >= 1 && f.timeout_seconds <= 900 && f.memory_mb >= 128 && f.memory_mb <= 10240])
    error_message = "Timeout must be 1 to 900 seconds (Lambda maximum) and memory 128 to 10240 MB."
  }

  validation {
    condition     = alltrue([for f in values(var.functions) : f.batch_size >= 1 && f.batch_size <= 10 && f.reserved_concurrency >= 1 && f.max_receive_count >= 1 && f.max_receive_count <= 1000 && f.backoff_base_seconds >= 1])
    error_message = "Batch size must be 1 to 10, reserved concurrency at least 1, max receive count 1 to 1000 and backoff base at least 1 second."
  }

  validation {
    condition = alltrue([
      for f in values(var.functions) :
      length(setunion(f.read.kms_classes, f.write.kms_classes)) == length(setintersection(setunion(f.read.kms_classes, f.write.kms_classes), ["telemetry", "objects", "records"]))
    ])
    error_message = "A function may use only the telemetry, objects and records key classes. The personal and restricted classes are never granted to an inference function (ASM-165)."
  }

  validation {
    condition = alltrue([
      for f in values(var.functions) :
      alltrue([for arn in concat(f.read.s3_object_arns, f.read.dynamodb_table_arns, f.write.dynamodb_table_arns, f.write.sns_topic_arns) : startswith(arn, "arn:") && !contains(["*", "arn:aws:s3:::*", "arn:aws:s3:::*/*"], arn)])
    ])
    error_message = "Every permission target must be an explicit ARN; a bare wildcard is rejected."
  }

  validation {
    condition = alltrue([
      for f in values(var.functions) :
      can(regex("^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$", f.inference.model_id)) && !anytrue([for prefix in ["us.", "eu.", "apac.", "global."] : startswith(f.inference.model_id, prefix)])
    ])
    error_message = "Model ID must be a foundation model identifier; inference profile identifiers (cross-Region prefixes) are not granted (architecture section 11)."
  }

  validation {
    condition     = alltrue([for f in values(var.functions) : alltrue([for principal in f.queue_senders.service_principals : endswith(principal, ".amazonaws.com")]) && (length(f.queue_senders.service_principals) == 0 || length(f.queue_senders.source_arns) > 0)])
    error_message = "Queue sender principals must be AWS service principals and must be scoped by at least one source ARN."
  }

  validation {
    condition     = alltrue([for f in values(var.functions) : alltrue([for key in keys(f.environment_variables) : !startswith(key, "RESULT_") && !startswith(key, "MODEL_") && key != "BACKOFF_BASE_SECONDS"])])
    error_message = "Environment variable names starting with RESULT_ or MODEL_, and BACKOFF_BASE_SECONDS, are set by the module."
  }
}

variable "kms_key_arns" {
  description = "Customer-managed key ARNs keyed by data class, the kms_key_arns output of the security module. The records key encrypts the queues, the dead-letter queues and the environment variables; the logs key encrypts the log groups."
  type        = map(string)
  nullable    = false

  validation {
    condition     = alltrue([for class in ["records", "logs"] : contains(keys(var.kms_key_arns), class)])
    error_message = "kms_key_arns must contain at least the records and logs classes."
  }

  validation {
    condition = alltrue([
      for f in values(var.functions) :
      alltrue([for class in concat(f.read.kms_classes, f.write.kms_classes) : contains(keys(var.kms_key_arns), class)])
    ])
    error_message = "Every key class named by a function must exist in kms_key_arns."
  }
}

variable "log_retention_days" {
  description = "Retention of every function log group, in days. A CloudWatch Logs retention value; the observability design uses 365."
  type        = number
  nullable    = false

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "Log retention must be a value that CloudWatch Logs accepts and must not be 0 (never expire)."
  }
}

variable "name_prefix" {
  description = "Prefix of every physical name, normally client-project-environment. At most 16 characters so that names stay within the 28 character cap of PC-IAC-003."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.name_prefix)) && length(var.name_prefix) <= 16
    error_message = "Name prefix must be lowercase alphanumeric words joined by hyphens, at most 16 characters (PC-IAC-003 28 character cap)."
  }
}

variable "permissions_boundary_arn" {
  description = "Optional permissions boundary attached to every function role. Null attaches none."
  type        = string
  default     = null

  validation {
    condition     = var.permissions_boundary_arn == null || startswith(coalesce(var.permissions_boundary_arn, "x"), "arn:")
    error_message = "Permissions boundary must be an ARN or null."
  }
}

variable "project" {
  description = "Project governance value from the root. At most 15 lowercase alphanumeric characters (PC-IAC-003)."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]{1,15}$", var.project))
    error_message = "Project must be 1 to 15 lowercase alphanumeric characters."
  }
}

variable "result_record_attributes" {
  description = "Attribute names under which every function persists the result: the UTC timestamp, the confidence in [0, 1] and the identifier of the source object (architecture section 5). They reach the function as environment variables."
  type = object({
    timestamp     = optional(string, "result_at")
    confidence    = optional(string, "confidence")
    source_object = optional(string, "source")
  })
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for name in values(var.result_record_attributes) : can(regex("^[a-z][a-z0-9_]{0,62}$", name))]) && length(distinct(values(var.result_record_attributes))) == 3
    error_message = "The three result attribute names must be distinct snake_case names."
  }
}
