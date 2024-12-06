# tf-module-gcp-gidc-gcs

This module is used to create single gcs buckets. It uses two resources from the google provider:
- [google_storage_bucket](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket)
- [google_storage_bucket_iam_member](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam)

## Prerequisites

- terraform >=0.14.0

## Inputs

> Inputs without defaults are **required**

| Key | Description | Values | Default |
|-|-|-|-|
| `project_id` | Project ID | `(string)` | |
| `location` | GCS location | `NORTHAMERICA-NORTHEAST1` / `NORTHAMERICA-NORTHEAST2` | |
| `gcs_bucket` | custom object | `(map)` | |
| `object_admins ` | list of object admins | `(list(string))` | null |
| `object_creators` | list of object creators | `(list(string))` | null |
| `object_viewers` | list of object viewers| `(list(string))` | null |

## gcs_bucket object
| Key | Description | Values | Default |
|-|-|-|-|
| `bucket_name` | Bucket Name | `(string)` | null |
| `suffix` | Creates a bucket name by appending the provided suffix to the project_id | `(string)` | null |
| `storage_class` | storage class of ojects | `STANDARD` / `NEARLINE` / `COLDLINE` / `ARCHIVE` | null |
| `force_destroy` | if true, allows non-empty buckets to be destroyed | `true` / `false` | `false` |
| `versioning` | if true, enables object versioning | `true` / `false` | false |
| `lifecycle` | list of custom objects | `(list(map))` | null |
| `log_bucket` | destination bucket for logs | `(string)` | null |
| `log_object_prefix` | prefix to add to logs. If not provided, GCS defaults to the bucket name. | `(map)` | null |

## lifecycle object
| Key | Description | Values | Default |
|-|-|-|-|
| `target` | action or destition storage class for lifecycle rules | `Delete` / `STANDARD` / `NEARLINE` / `COLDLINE` / `ARCHIVE`  | |
| `age` | minimum age in days of objects to apply lifecyle rules to | `(int)` | null |
| `num_newer_versions` | minimum number of newer version of objects required before applying lifecyle rules| `(int)` | null |

One of `age` or `num_newer_versions` is required.


## object_admins, object_creators, object_viewers
IaM roles are provided to user or group emails, which must be provided it the form:  

`user:<user.email@telus.com>` or `group:<group.email@telus.com>` or `serviceAccount:<serviceAccount.email@telus.com>`

## Output
The module outputs the following bucket properties:
- bucket_name
- bucket_url
- bucket_self_link

## Usage

The following variables are required:
- project_id
- location
- gcs_bucket

Within the `gcs_bucket` object, one of `bucket_name` or `suffix` are must be provided. If both are present, `suffix` will be ignored.

If `num_newer_versions` is provided, `versioning = true` must also be provided.

### Example 1 - Basic bucket with IaM
#### buckets.tf
```
module "media" {
  count          = lookup(var.buckets, "media", null) != null ? 1 : 0
  gcs_bucket     = var.buckets.media
  project_id     = var.project_id
  location       = var.region
  object_viewers = var.object_viewers
  object_admins  = var.object_admins
  source         = "git::ssh://git@github.com/telus/tf-module-gcp-gidc-gcs?ref=dev"
}
```
#### pr.tfvars
```
region = "northamerica-northeast1"

project_id = "cio-gidc-some-project-ce087d"

buckets = {
  media = {
    suffix = "media",
  }
}

object_viewers = [
  "user:some.user@telus.com",
  "group:dlsomegroup@telus.com"
]

object_admins = [
  "group:dlsomeothergroup@telus.com"
]
```

### Example 2 - Bucket with IaM, versioning, and lifecycle
#### buckets.tf
```
module "docs" {
  count           = lookup(var.buckets, "docs", null) != null ? 1 : 0
  gcs_bucket      = var.buckets.docs
  project_id      = var.project_id
  location        = var.region
  object_viewers  = var.object_viewers
  object_creators = var.object_creators
  source          = "git::ssh://git@github.com/telus/tf-module-gcp-gidc-gcs?ref=dev"
}
```
#### pr.tfvars
```
region = "northamerica-northeast1"

project_id = "cio-gidc-some-project-ce087d"

buckets = {
  docs = {
    bucket_name        = "my-project-id-docs",
    versioning         = true,
    lifecycle          = [
      {
        target   = "Delete",
        num_newer_versions = 3
      }
    ]
  }
}

object_viewers = [
  "user:some.user@telus.com",
  "group:dlsomegroup@telus.com"
]

object_creators = [
  "group:dlsomeothergroup@telus.com"
]
```
