# Enable required services
resource "google_project_service" "project_services" {
  project   = var.project_id
  for_each  = toset([
    "iam.googleapis.com",
    "storage.googleapis.com",
    "compute.googleapis.com",
    "pubsub.googleapis.com"
  ])
  service = each.value
  disable_dependent_services  = false
  disable_on_destroy          = false
}