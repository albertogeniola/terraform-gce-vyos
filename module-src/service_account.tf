resource "google_service_account" "vyos_compute_sa" {
  project      = var.project_id
  account_id   = "${var.instance_name}-sa"
  display_name = "Service Account mounted on ${var.instance_name} compute instances"
}

resource "google_project_iam_member" "sa_log_writer" {
  project      = var.project_id
  member      = "serviceAccount:${google_service_account.vyos_compute_sa.email}"
  role        = "roles/logging.logWriter"
  depends_on  = [google_service_account.vyos_compute_sa]
}
resource "google_project_iam_member" "sa_metric_writer" {
  project      = var.project_id
  member      = "serviceAccount:${google_service_account.vyos_compute_sa.email}"
  role        = "roles/monitoring.metricWriter"
  depends_on  = [google_service_account.vyos_compute_sa]
}