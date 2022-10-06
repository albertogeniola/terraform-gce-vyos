# VyOS instance
module "vyos_instance" {
    source = "../../module-src"
    
    # Project info
    project_id      = var.project_id
    gcp_region      = var.region
    instance_name   = "vyos-instance"

    # Dynamic config
    configuration_bucket_name   = "${var.project_id}-vyos-conf"
    configuration_bucket_path   = "configuration"
    vyos_configuration_content  = file("vyos.config")

    # GCE config
    instance_tier               = "n2-standard-2"
    instance_zone               = var.zone
    instance_vyos_image_name    = "vyos-gce" # ATTENTION! THIS IS THE NAME OF THE VYOS IMAGE IMPORTED FROM THIS REPO.

    # We want to be able to connect via serial port
    enable_serial_port_connection = true
    
    # Networking configuration
    networks_configuration = {
      
      # Primary interface
      0 = {
        network_project_id  = var.project_id
        network             = google_compute_network.vyos_external_vpc.self_link
        subnetwork          = google_compute_subnetwork.vyos_external_subnet.self_link
        network_ip          =  local.external_vyos_ip
        
        assign_external_ip = true
        static_external_ip = null

        # Enable IAP connections on the external interface.
        create_iap_ssh_firewall_rule = true
      },
      # Secondary interface
      1 = {
        network_project_id  = var.project_id
        network             = google_compute_network.vyos_internal_vpc.self_link
        subnetwork          = google_compute_subnetwork.vyos_internal_subnet.self_link
        network_ip          = local.internal_vyos_ip

        assign_external_ip = false
        static_external_ip = null

        create_iap_ssh_firewall_rule = true
      }
    }
}
