resource "google_storage_bucket" "artifact_bucket" {
  name          = local.artifact_bucket
  location      = var.gcp_region
}

resource "google_storage_bucket" "conf_file_bucket" {
  name          = local.conf_bucket
  location      = var.gcp_region
}

resource "google_storage_bucket_object" "conf_file_object" {
  name    = local.conf_object
  bucket  = google_storage_bucket.conf_file_bucket.name
  content = var.vyos_configuration_content
}

resource "google_storage_notification" "configuration_update" {
  bucket         = google_storage_bucket.conf_file_bucket.name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.configuration_update_topic.id
  event_types    = ["OBJECT_FINALIZE", "OBJECT_METADATA_UPDATE"]
  custom_attributes = {
    # TODO: control auto-apply via custom attributes?
  }
  depends_on = [google_pubsub_topic_iam_member.pubsub_notification_event]
}

resource "google_storage_bucket_iam_member" "instance_sa_bucket_permissions" {
  for_each  = toset([
    "roles/storage.objectViewer",
    "roles/storage.legacyBucketReader",
  ])
  bucket    = google_storage_bucket.conf_file_bucket.name
  role      = each.value
  member    = "serviceAccount:${google_service_account.vyos_compute_sa.email}"
  depends_on = [google_service_account.vyos_compute_sa]
}