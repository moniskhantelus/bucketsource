#Mandatory input variables
variable "project_id" {
  description = "project name"
  type        = string
}

variable "location" {
  description = "google location"
  type        = string
}

variable "gcs_bucket" {
  description = "a gcs bucket"
  type = object({
    bucket_name       = optional(string)
    suffix            = optional(string)
    storage_class     = optional(string)
    force_destroy     = optional(bool)
    versioning        = optional(bool)
    lifecycle         = optional(list(map(string)))
    log_bucket        = optional(string)
    log_object_prefix = optional(string)
  })
  default = {
    bucket_name       = null
    suffix            = null
    storage_class     = null
    force_destroy     = null
    versioning        = null
    lifecycle         = null
    log_bucket        = null
    log_object_prefix = null
    object_admins     = null
    object_creators   = null
    object_viewers    = null
  }
}

variable "object_admins" {
  description = "object admins"
  type        = list(string)
  default     = null
}

variable "object_creators" {
  description = "object creators"
  type        = list(string)
  default     = null
}

variable "object_viewers" {
  description = "object viewers"
  type        = list(string)
  default     = null
}