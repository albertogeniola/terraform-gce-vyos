resource "google_compute_instance" "vyos" {
  project         = var.project_id
  name            = var.instance_name
  machine_type    = var.instance_tier
  zone            = var.instance_zone

  tags            = var.instance_tags
  can_ip_forward  = true

  boot_disk {
    initialize_params {
      image = data.google_compute_image.vyos.self_link
    }
  }

  dynamic "network_interface" {
    for_each = var.networks_configuration
    content {
      network     = network_interface.value.network
      subnetwork  = network_interface.value.subnetwork
      network_ip  = network_interface.value.network_ip

      dynamic "access_config" {
        for_each = network_interface.value.assign_external_ip ? {1=1} : {}
        content {
          nat_ip = network_interface.value.static_external_ip
          network_tier = "PREMIUM"
        }
      }
    }
  }
  
  service_account {
    email  = google_service_account.vyos_compute_sa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    "pubsub-subscription" = google_pubsub_subscription.vyos_instance_subscription.name
    "configuration_bucket_id" = google_storage_bucket_object.conf_file_object.bucket
    "configuration_object_id" = google_storage_bucket_object.conf_file_object.name
    "serial-port-enable"  = upper(var.enable_serial_port_connection)
    "enable-oslogin"      = "FALSE"
    "user-data"           = var.user_data_content
  }

  depends_on = [
    data.google_iam_policy.subscription_subscriber
  ]

  lifecycle {
    ignore_changes = [
      metadata["ssh-keys"]
    ]
  }
}