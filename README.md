# GCE VyOS module
[VyOS][1] is a router open source operating system, based on the previous [vyatta][2] virtual router implementation.
VyOS runs both on bare-metal devices as well as on all major cloud providers, including Google Cloud Platform.

## Motivation
At the time of writing, there is no easy-to-go way to get VyOS running on GCP, except the Google Marketplace deploy. 
While the [current version of VyOS][4] available on GCP marketplace is paid (even if it is an open-source project)
it is not updated and does not come with Google Compute agent nor Google Ops Agent installed.
This module aims at enabling IaC projects to take advantage of VyOS instances with ease, following a more IaC-oriented approach.

## Features
This module achieves two major objectives:
- Provides a way for deploying a VyOS Equuleus 1.3 GCE Image on GCP
- Enables the VyOS instance to update its configuration using Cloud Storage and Pub/Sub notifications
- Enables users connecting via IAP/GCLOUD ssh to administer the VyOS instance with the built-in command line

## Imge Prerequisites
This Terraform module spawns a GCE instance running a special GCE Image, which needs to be referenced in the module.

You should create the __VyOS GCE image__ on the GCP project where to deploy this module.
You can either build that image yourself and install the necessary components to make the image work on GCE instances, or you can
simply import the GCE image (vyos-equuleus-gce-image.tar.gz) built on this repository, [available here](https://github.com/albertogeniola/terraform-gce-vyos/releases).

To create the GCE image starting from that tarball, simply update it into a GCS bucket and create a new GCE image starting from the uploaded file. 
More info about this process can be found on the [official GCP documentation](https://cloud.google.com/compute/docs/images/create-custom#create_image).

### Building VyOS GCE Image
This image is built via the build scripts provided by the VyOS team and enriched with the necessary configurations and scripts
useful to run on the GCP environment. At the time of writing, the GCE image on this repository is built as follows:
1. Build the VyOS Equuleus 1.3 ISO, using the official build-script;
1. Build the base VyOS Equuleus 1.3 GCE Image, using the official build-script;
1. Configure and patch the image to run correctly on GCE:
   - Install the GCE Linux Guest Agent
   - Install the GCE Linux Ops Agent (which includes metrics and logging features) against Stackdriver
   - Configure the file VyOS boot config to use a single instance with DHCP
   - Map the metadata.google.internal host to 169.256.169.256
1. Install the Configuration Reloader service to automatically fetch the configuration from GCS
1. Install the Login Helper service to handle SSH users login via VyOS


_Note_: this module won't take care of enabling the necessary APIs. It is developer's responsibility to enable them in the root module.

> __Please note that covering the build phase of the image is out of the scope of this document.__
> 
> That being said, if you plan to build the VyOS image by yourself, please inject the repository contents of `vyos-gce-image/chroot-patches/opt/gce_helper` 
> and `vyos-gce-image/chroot-patches/etc/systemd/system` respectively to `/opt/gce_helper` and `/etc/systemd/system` (on the target image).
> Also, make sure to override the default vyos `config.boot.default` file with the one provided in this repository.
> Eventually, make sure to install the GCE agent and the ops agent. You can see how this is done in this repository by lookig at the `99-gce-agent.chroot`
> shell script.


# Limitations
Some organizational policy might require an exception for this module to work.
For instance, the `constraints/storage.uniformBucketLevelAccess` constraint should not apply to the bucket where the configuration is held, as the current
version of the module works with ACLs on single objects.
If you plan to use VyOS instance with a public IP assigned, you should make sure that the policy `constraints/compute.vmExternalIpAccess` does allow that.

Moreover, at the time of writing, the provided GCE VyOS image does not comply with shielded image requirements nor supports OS-LOGIN. 
Therefore `constraints/compute.requireShieldedVm` and `constraints/compute.requireOsLogin` org policies should allow an exception for the VyOS intance.

## Usage
Refer to the `example` folder for some quick examples on how to use this module.


## Module reference
### Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 4.37.0 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vyos_instance"></a> [vyos\_instance](#module\_vyos\_instance) | ../../module-src | n/a |

### Resources

| Name | Type |
|------|------|
| [google_compute_network.vyos_external_vpc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_network.vyos_internal_vpc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_subnetwork.vyos_external_subnet](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_compute_subnetwork.vyos_internal_subnet](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | n/a | `any` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | n/a | `any` | n/a | yes |
| <a name="input_zone"></a> [zone](#input\_zone) | n/a | `any` | n/a | yes |

### Outputs

No outputs.

## Licensing notes
This module is provided as is, with absolutely no warranty.

Quoting the [original documentation][3], we read:
```
VyOS is now free as in speech, but not as in beer. 
This means that while VyOS is still an open source project, 
the release ISOs are no longer free and can only be obtained 
via subscription, or by contributing to the community.
``` 


[1]: https://vyos.io/
[2]: https://en.wikipedia.org/wiki/Vyatta
[3]: https://docs.vyos.io/en/equuleus/contributing/build-vyos.html#prerequisites
[4]: https://console.cloud.google.com/marketplace/details/sentrium-sl/vyos?pli=1&__hstc=29142691.81c103d48b29bf69a308c8fc19c4c385.1589665573318.1599490605499.1599492713182.137&__hssc=29142691.11.1599492713182&__hsfp=2286654099&hsCtaTracking=9eef7ede-be44-49bd-aec6-f348ff4ab420%7C881f8bd5-facc-4f16-9640-50339c90751d
[5]: https://github.com/GoogleCloudPlatform/guest-agent
[6]: https://cloud.google.com/monitoring/agent/ops-agent

