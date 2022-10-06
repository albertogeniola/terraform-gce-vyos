data "google_compute_image" "debian" {
  family    = "debian-11"
  project   = "debian-cloud"
}

resource "google_compute_instance" "internal_instance" {
  project       = var.project_id
  name          = "internal-vm"
  machine_type  = "n2-standard-2"
  zone          = "europe-west8-b"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
    }
  }
  tags = [local.allow_iap_ssh_inbound_tag]
  network_interface {
    network     = google_compute_network.vyos_internal_vpc.self_link
    subnetwork  = google_compute_subnetwork.vyos_internal_subnet.self_link
    network_ip  = local.internal_test_vm_ip
  }

  depends_on = [
    module.vyos_instance_1,
    module.vyos_instance_2
  ]
}