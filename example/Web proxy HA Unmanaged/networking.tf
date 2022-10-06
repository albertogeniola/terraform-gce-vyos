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
  project       = var.project_id 
  name          = "fw-inbound-proxy-internal"
  network       = google_compute_network.vyos_internal_vpc.self_link
  source_ranges = [local.internal_subnet_cidr]
  allow {
    protocol  = "tcp"
    ports     = [ 3128 ]
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

# Enable ilb health-checks
resource "google_compute_firewall" "ilb_health_checks" {
  project       = var.project_id 
  name          = "fw-inbound-ilb-hc"
  network       = google_compute_network.vyos_internal_vpc.self_link
  target_service_accounts = [module.vyos_instance_1.sa_email, module.vyos_instance_2.sa_email]
  source_ranges = local.ilb_hc_cidrs
  allow {
    protocol  = "tcp"
    ports     = [ 3128 ]
  }
}

# Instance group for the VyOS VMs
resource "google_compute_instance_group" "vyos_web_proxy_unmanaged_primary" {
  project   = var.project_id
  zone      = var.zone_primary
  name      = "vyos-web-proxy-primary"
  
  instances = [
    module.vyos_instance_1.vm_id
  ]
  network = google_compute_network.vyos_external_vpc.self_link
  named_port {
    name = "webproxy"
    port = 3128
  }
}
resource "google_compute_instance_group" "vyos_web_proxy_unmanaged_secondary" {
  project   = var.project_id
  zone      = var.zone_secondary
  name      = "vyos-web-proxy-secondary"
  
  instances = [
    module.vyos_instance_2.vm_id
  ]
  network = google_compute_network.vyos_external_vpc.self_link
  named_port {
    name = "webproxy"
    port = 3128
  }
}

# Backend service
resource "google_compute_region_backend_service" "vyos_web_proxy_backend" {
  project               = var.project_id
  name                  = "vyos-web-proxy"
  region                = var.region
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"
  timeout_sec           = 10
  health_checks         = [google_compute_region_health_check.vyos_webproxy_hc.self_link]
  
  # We need to specify the network to be used as backend service, as our VMs do have multiple NICs
  #  and we want to load-balance on the secondary NIC (internal), which is connected to the internal
  #  vpc.
  network               = google_compute_network.vyos_internal_vpc.self_link 
  
  backend {
    group = google_compute_instance_group.vyos_web_proxy_unmanaged_primary.self_link
    balancing_mode  = "CONNECTION"
  }
  backend {
    group = google_compute_instance_group.vyos_web_proxy_unmanaged_secondary.self_link
    balancing_mode  = "CONNECTION"
  }
}

# Health Checks for the backend service
resource "google_compute_region_health_check" "vyos_webproxy_hc" {
  project             = var.project_id
  region              = var.region
  name                = "vyos-webproxy-hc"
  
  tcp_health_check {
    port = 3128
  }
}

# Forwarding rule for VyOS ILB
resource "google_compute_forwarding_rule" "google_compute_forwarding_rule" {
  project               = var.project_id
  name                  = "proxy-ilb-forwarding-rule"
  region                = var.region
  depends_on            = [google_compute_subnetwork.vyos_internal_subnet]
  ip_address            = local.proxy_ilb_address
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL"
  ports                 = [3128]
  backend_service       = google_compute_region_backend_service.vyos_web_proxy_backend.self_link
  
  network               = google_compute_network.vyos_internal_vpc.self_link
  subnetwork            = google_compute_subnetwork.vyos_internal_subnet.self_link
}

locals {
  external_subnet_cidr        = "10.0.0.0/16"
  internal_subnet_cidr        = "10.10.0.0/16"
  allow_iap_ssh_inbound_tag   = "ssh-iap"
  iap_cidrs                   = ["35.235.240.0/20"]
  proxy_ilb_address           = cidrhost(local.internal_subnet_cidr, 3)
  external_vyos_1_ip = cidrhost(local.external_subnet_cidr, 4)
  external_vyos_2_ip = cidrhost(local.external_subnet_cidr, 5)
  internal_vyos_1_ip = cidrhost(local.internal_subnet_cidr, 4)
  internal_vyos_2_ip = cidrhost(local.internal_subnet_cidr, 5)

  ilb_hc_cidrs       = ["35.191.0.0/16", "130.211.0.0/22"]
}