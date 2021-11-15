##################################
# TOPIC CONFIGURATION            #
##################################
resource "google_pubsub_topic" "configuration_update_topic" {
  project = var.project_id
  name    = "vyos.${var.instance_name}.configuration"
}

resource "google_pubsub_topic_iam_member" "pubsub_notification_event" {
  project = var.project_id
  topic   = google_pubsub_topic.configuration_update_topic.id
  role    = "roles/pubsub.publisher"
  member = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}

##################################
# SUBSCRIPTION CONFIGURATION     #
##################################
resource "google_pubsub_subscription" "vyos_instance_subscription" {
  project = var.project_id
  name    = "instance-${var.instance_name}"
  topic   = google_pubsub_topic.configuration_update_topic.name
  ack_deadline_seconds = 30
}

data "google_iam_policy" "subscription_subscriber" {
  binding {
    role    = "roles/pubsub.subscriber"
    members = [
      "serviceAccount:${google_service_account.vyos_compute_sa.email}"
    ]
  }
}

resource "google_pubsub_subscription_iam_policy" "instance_subscriber" {
  subscription = google_pubsub_subscription.vyos_instance_subscription.name
  policy_data  = data.google_iam_policy.subscription_subscriber.policy_data
}