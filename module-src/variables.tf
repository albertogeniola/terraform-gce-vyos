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
  type = list(object({
    network=string,
    subnetwork=string,
    network_ip=string,
    access_config=object({
      nat_ip=string,
      public_ptr_domain_name=string,
      network_tier=string
    })
  }))
}