# Define an external VPC
resource "google_compute_network" "vyos_external_vpc" {
  name                      = "vyos-external-vpc"
  project                   = var.project_id 
  auto_create_subnetworks   = false
}

resource "google_compute_subnetwork" "vyos_external_subnet" {
  region                    = var.region
  name                      = "vyos-external-subnet"
  project                   = var.project_id 
  network                   = google_compute_network.vyos_external_vpc.self_link
  ip_cidr_range             = local.external_subnet_cidr
  private_ip_google_access  = true  
}

# Define an internal VPC
resource "google_compute_network" "vyos_internal_vpc" {
  name                      = "vyos-internal-vpc"
  project                   = var.project_id 
  auto_create_subnetworks   = false
}

resource "google_compute_subnetwork" "vyos_internal_subnet" {
  region                    = var.region
  name                      = "vyos-internal-subnet"
  project                   = var.project_id 
  network                   = google_compute_network.vyos_internal_vpc.self_link
  ip_cidr_range             = local.internal_subnet_cidr
  private_ip_google_access  = true  
}

# Enable firewall rules for Proxy access for the internal VM
resource "google_compute_firewall" "proxy_internal_vms" {
  project                 = var.project_id 
  name                    = "fw-inbound-proxy-internal"
  network                 = google_compute_network.vyos_internal_vpc.self_link
  source_ranges           = [local.internal_subnet_cidr]
  target_service_accounts = [module.vyos_instance.sa_email]
  allow {
    protocol  = "tcp"
  }
  allow {
    protocol  = "udp"
  }
}

# Enable firewall rules for SSH access for the internal VM
resource "google_compute_firewall" "ssh_iap_internal_vms" {
  project       = var.project_id 
  name          = "fw-inbound-iap-ssh"
  network       = google_compute_network.vyos_internal_vpc.self_link
  target_tags   = [local.allow_iap_ssh_inbound_tag]
  source_ranges = local.iap_cidrs
  allow {
    protocol  = "tcp"
    ports     = [ 22 ]
  }
}

# Default route for internal VPC
resource "google_compute_route" "name" {
  project     = var.project_id
  name        = "default-route-to-vyos-nat"
  dest_range  = "0.0.0.0/0"
  network     = google_compute_network.vyos_internal_vpc.self_link
  next_hop_ip = local.internal_vyos_ip
  priority    = 100
}

locals {
  external_subnet_cidr        = "10.0.0.0/16"
  internal_subnet_cidr        = "10.10.0.0/16"
  allow_iap_ssh_inbound_tag   = "ssh-iap"
  iap_cidrs                   = ["35.235.240.0/20"]
  external_vyos_ip = cidrhost(local.external_subnet_cidr, 3)
  internal_vyos_ip = cidrhost(local.internal_subnet_cidr, 3)

  ilb_hc_cidrs       = ["35.191.0.0/16", "130.211.0.0/22"]
}