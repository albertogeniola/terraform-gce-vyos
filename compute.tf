resource "google_compute_instance" "vyos" {
  name          = var.instance_name
  machine_type  = var.instance_tier
  zone          = var.instance_zone

  tags          = var.instance_tags

  boot_disk {
    initialize_params {
      image = "${var.project_id}/${var.instance_vyos_image_name}"
    }
  }

  network_interface {
    network     = var.instance_network_self_link
    subnetwork  = var.instance_subnet_network_self_link
    network_ip  = var.instance_private_ip

    access_config {
      // Ephemeral public IP
      # TODO: control whether the instance is given a public ip via variables
    }
  }

  service_account {
    email  = google_service_account.vyos_compute_sa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    "pubsub-subscription" = google_pubsub_subscription.vyos_instance_subscription.name
  }

  depends_on = [
    google_storage_bucket_object.conf_file_object,
    data.google_iam_policy.subscription_subscriber
  ]
}