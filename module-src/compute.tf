resource "google_compute_instance" "vyos" {
  project       = var.project_id
  name          = var.instance_name
  machine_type  = var.instance_tier
  zone          = var.instance_zone

  tags          = var.instance_tags

  boot_disk {
    initialize_params {
      image = "${var.project_id}/${var.instance_vyos_image_name}"
    }
  }

  dynamic "network_interface" {
    for_each = toset(var.networks_configuration)
    content {
      network     = network_interface.value.network
      subnetwork  = network_interface.value.subnetwork
      network_ip  = network_interface.value.network_ip

      access_config {
        nat_ip = network_interface.value.access_config.nat_ip
        public_ptr_domain_name = network_interface.value.access_config.public_ptr_domain_name
        network_tier = network_interface.value.access_config.network_tier
      }
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