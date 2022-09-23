data google_storage_project_service_account gcs_account {
  project = var.project_id
}

data "google_compute_image" "vyos" {
  project = local.vyos_image_project_id
  name    = var.instance_vyos_image_name
  
}