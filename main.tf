# local variable for location
locals {
  #multi region not supported
  location = upper(var.location)
  throw_invalid_location_defined = (length(regexall("NORTHAMERICA-NORTHEAST(1|2)", local.location)) == 0 ?
  contains("invalid location", "must match NORTHAMERICA-NORTHEAST(1|2)") : null)
}

# local variable for bucket_name
locals {
  bucket_name = (var.gcs_bucket.bucket_name != null ?
  var.gcs_bucket.bucket_name : (var.gcs_bucket.suffix != null ? "${var.project_id}-${var.gcs_bucket.suffix}" : null))
  throw_no_name_defined = local.bucket_name == null ? contains("bucket_name is not defined", "bucket_name or suffix is required") : null
}

# local lifecycle_rule used to trigger the dynamic block for lifecycle_rule if needed
locals {
  # validate target
  valid_target = lookup(var.gcs_bucket, "lifecycle", null) != null ? [for each in var.gcs_bucket.lifecycle :
    (lookup(each, "target", null) != null ? (length(regexall("^(DELETE|STANDARD|NEARLINE|COLDLINE|ARCHIVE)$", upper(each.target))) != 0 ? true :
      contains("target value is invalid", "must be null|Delete|STANDARD|NEARLINE|COLDLINE|ARCHIVE")) :
    contains("target value is invalid", "must be null|Delete|STANDARD|NEARLINE|COLDLINE|ARCHIVE"))
  ] : null

  lifecycle_rules = lookup(var.gcs_bucket, "lifecycle", null) != null ? [for each in var.gcs_bucket.lifecycle :
    merge(each, { "action_type" = (lower(each.target) == "delete" ? "Delete" : "SetStorageClass") },
      { "storage_class" = (length(regexall("^(STANDARD|NEARLINE|COLDLINE|ARCHIVE)$", upper(each.target))) != 0 ? upper(each.target) : null) }
  )] : []

  # validate versioning = true if num_newer_versions used
  valid_versioning = [for each in local.lifecycle_rules :
    (lookup(each, "num_newer_versions", null) != null ? (var.gcs_bucket.versioning == true ? true :
    contains("num_newer_versions cannot be used", "unless version is true")) : true)
  ]

}

# local logging used to trigger the dynamic block for logging if needed
locals {
  logging = var.gcs_bucket.log_bucket != null ? true : false
}

# create gcs bucket instance
resource "google_storage_bucket" "bucket" {
  name                        = local.bucket_name
  location                    = local.location
  project                     = var.project_id
  uniform_bucket_level_access = true
  storage_class               = var.gcs_bucket.storage_class
  force_destroy               = var.gcs_bucket.force_destroy
  dynamic "versioning" {
    for_each = var.gcs_bucket.versioning == true ? [1] : []
    content {
      enabled = true
    }
  }
  dynamic "lifecycle_rule" {
    for_each = local.lifecycle_rules
    content {
      action {
        type          = lifecycle_rule.value["action_type"]
        storage_class = lookup(lifecycle_rule.value, "storage_class", null)
      }
      condition {
        age                = lookup(lifecycle_rule.value, "age", null)
        num_newer_versions = lookup(lifecycle_rule.value, "num_newer_versions", null)
      }
    }
  }
  dynamic "logging" {
    for_each = local.logging ? [1] : []
    content {
      log_bucket        = var.gce_instance.log_bucket
      log_object_prefix = var.gce_instance.log_object_prefix
    }
  }
}

resource "google_storage_bucket_iam_member" "object_admin" {
  for_each = var.object_admins != null ? toset(var.object_admins) : []
  bucket   = google_storage_bucket.bucket.name
  role     = "roles/storage.objectAdmin"
  member   = each.key
}

resource "google_storage_bucket_iam_member" "object_creator" {
  for_each = var.object_creators != null ? toset(var.object_creators) : []
  bucket   = google_storage_bucket.bucket.name
  role     = "roles/storage.objectCreator"
  member   = each.key
}

resource "google_storage_bucket_iam_member" "object_viewer" {
  for_each = var.object_viewers != null ? toset(var.object_viewers) : []
  bucket   = google_storage_bucket.bucket.name
  role     = "roles/storage.objectViewer"
  member   = each.key
}

output "bucket_name" {
  value       = google_storage_bucket.bucket.name
  description = "The bucket name"
}

output "bucket_url" {
  value       = google_storage_bucket.bucket.url
  description = "The bucket name"
}

output "bucket_self_link" {
  value       = google_storage_bucket.bucket.self_link
  description = "The bucket name"
}