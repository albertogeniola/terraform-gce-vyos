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
    network_ip  = cidrhost(google_compute_subnetwork.vyos_internal_subnet.ip_cidr_range, 4)
  }

  metadata_startup_script = <<EOF
  echo "" > /etc/profile.d/terraform-gce-proxy.sh
  echo "export http_proxy=\"http://${local.internal_subnet_ip}:3128/\"">>/etc/profile.d/proxy.sh
  echo "export https_proxy=\"http://${local.internal_subnet_ip}:3128/\"">>/etc/profile.d/proxy.sh
  echo "export ftp_proxy=\"http://${local.internal_subnet_ip}:3128/\"">>/etc/profile.d/proxy.sh
  echo "export no_proxy=\"127.0.0.1,localhost\"">>/etc/profile.d/proxy.sh
  echo "export HTTP_PROXY=\"http://${local.internal_subnet_ip}:3128/\"">>/etc/profile.d/proxy.sh
  echo "export HTTPS_PROXY=\"http://${local.internal_subnet_ip}:3128/\"">>/etc/profile.d/proxy.sh
  echo "export FTP_PROXY=\"http://${local.internal_subnet_ip}:3128/\"">>/etc/profile.d/proxy.sh
  echo "export NO_PROXY=\"127.0.0.1,localhost\"">>/etc/profile.d/proxy.sh

  # Test the curl feature
  sleep 30 # Give some time to the proxy to spawn
  curl -x http://${local.internal_subnet_ip}:3128 -o /root/proxy-test.json https://api.ipify.org?format=json
  EOF

  depends_on = [
    module.vyos_instance
  ]
}