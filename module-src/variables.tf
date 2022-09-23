variable "project_id" {
  description = "Google project id where to spawn the VyOs instance"
}

variable "gcp_region" {
  description = "Default GCP region where to spawn resources"
}

variable "configuration_bucket_name" {
  description = "Bucket name where to store VyOs instance configuration file"
  default     = null
}

variable "configuration_bucket_path" {
  description = "GCS object path where to store VyOs instance configuration file"
  default     = null
}

variable "vyos_configuration_content" {
  description = "Contents of the VyOs configuration to apply to the target instance"
}

variable "instance_name" {
  description = "Name to assign to the VyOs instance"
  default     = "vyos"
}

variable "instance_tier" {
  description = "Machine tier for the VyOs instance"
  default     = "e2-small"
}

variable "instance_zone" {
  description = "GCP Zone where to spawn the VyOs instance"
}

variable "instance_tags" {
  description = "Tags to assign to the vyos instance"
  default     = ["vyos"]
}

variable "instance_vyos_image_name" {
  description = "Instance image name"
}

variable "instance_vyos_image_region" {
  description = "Instance image region"
  default     = "EU"
}

variable "networks_configuration" {
  description = "Instance networking configuration."
  type = map(object({
    assign_external_ip=bool,
    static_external_ip=string,
    create_iap_ssh_firewall_rule=bool,
    network_project_id=string,
    network=string,
    subnetwork=string,
    network_ip=string,
  }))
}

variable "enable_serial_port_connection" {
  description = "When true, allows the connection via the serial port"
  default     = false
}

variable "user_data_content" {
  description = "Holds the content of the user-data metadata to be used as configuration script at instance boot."
  default     = ""
}