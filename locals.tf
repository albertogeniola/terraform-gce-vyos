locals {
  artifact_bucket = var.artifact_bucket_name == null ? "${var.project_id}-vyos-artifacts" : var.artifact_bucket_name
  conf_bucket = var.configuration_bucket_name == null ? "${var.project_id}-vyos-conf" : var.configuration_bucket_name
  conf_object = var.configuration_bucket_path == null ? "${var.instance_name}.conf": var.configuration_bucket_path
}