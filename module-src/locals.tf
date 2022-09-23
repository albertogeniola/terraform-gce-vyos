locals {
  conf_bucket = var.configuration_bucket_name == null ? "${var.project_id}-vyos-conf" : var.configuration_bucket_name
  conf_object = var.configuration_bucket_path == null ? "${var.instance_name}.conf": var.configuration_bucket_path
  vyos_image_project_id = var.instance_vyos_image_project_id == null ? var.project_id : var.instance_vyos_image_project_id
  IAP_RANGES = ["35.235.240.0/20"]
}