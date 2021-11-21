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

variable "artifact_bucket_name" {
  description = "Bucket used as artifact scratchpad to build the VyOs image"
  default     = null
}

variable "vyos_vanilla_image_name" {
  description = "Name for the vyos vanilla image to build"
  default     = "vyos-vanilla"
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

variable "instance_network_self_link" {
  description = "VPC network self-link where to attach the VyOs instance"
}

variable "instance_subnet_network_self_link" {
  description = "Subnet self-link where to attach che VyOs instance"
}

variable "instance_private_ip" {
  description = "Private network ip to assign to VyOs instance"
}

variable "instance_vyos_image_name" {
  description = "Instance image name"
}

variable "instance_vyos_image_region" {
  description = "Instance image region"
  default     = "EU"
}

variable "build_vyos_image" {
  description =<<EOF
When set to true, the module will build the vyos image with packer and name it as `instance_vyos_image_name`.
In case you have built the image manually, set this flag to false and reference the vyos image using the
`instance_vyos_image_name` variable."
EOF

}