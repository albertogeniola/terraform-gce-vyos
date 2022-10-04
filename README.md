# GCE VyOS module
[VyOS][1] is a router open source operating system, based on the previous [vyatta][2] virtual router implementation.
VyOS runs both on bare-metal devices as well as on all major cloud providers, including Google Cloud Platform.

## Motivation
At the time of writing, there is no easy-to-go way to get VyOS running on GCP, except the Google Marketplace deploy. 
While the [current version of VyOS][4] available on GCP marketplace is paid (even if it is an open-source project)
it is not updated and does not come with Google Compute agent nor Google Ops Agent installed.
This module aims at enabling IaC projects to take advantage of VyOS instances with ease, following a more IaC-oriented approach.

## Features
This module achieves the following major objectives:
- Provides a way for deploying a VyOS Equuleus 1.3 GCE Image on GCP
- Enables the VyOS instance to update its configuration using Cloud Storage and Pub/Sub notifications
- Enables users connecting via IAP/GCLOUD ssh to administer the VyOS instance with the built-in command line

### Why not simply using cloud-init?
Cloud-init is a great feature that allows initial configuration and bootstrapping of cloud images. VyOS has developed
a couple of modules that allow fetching and changing the configuration of the router at boot time, via metadata gathering,
specifically using the `user-data` key.

However, that approach has some major limitations:
- It works by issuing configuration commands (i.e. imperative) while the rest of the module works with declarative approach.
- It is limited to the maximum size of the metadata
- It requires a reboot to be reapplied (most likely a startup script)

This module uses a GCS file to hold the configuration state, fetched via pubsub event by a python daemon running on the VyOS instance.
However, the module still allows the developer to pass the user-data content, in case that is preferred.

## Image Prerequisites
This Terraform module requires a custom GCE Image to be built or imported into the GCP
project where the VyOS router will reside. You can either build and customize that image yourself (but chances are you landed on this page because you don't want to do so), 
or you can simply import the GCE image (vyos-equuleus-gce-image.tar.gz) built on this repository, [available here](https://github.com/albertogeniola/terraform-gce-vyos/releases).

To get the image ready by using the one built on this repository, simply download the __.ta.gz__ tarball and update it into a GCS bucket. Then, create a new GCE image starting 
from the uploaded file. More info about this process can be found on the [official GCP documentation](https://cloud.google.com/compute/docs/images/create-custom#create_image).

### Building VyOS GCE Image by your own
The GCE image is built via the build scripts provided by the VyOS team and enriched with the necessary configurations and scripts
needed to run on the GCP environment. At the time of writing, the GCE image on this repository is built as follows:
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


## Limitations
So far, the VyOS image has been tested only on n2 or n1 instance families. __Other instance families might not be supported__.

When using this module as part of an unmanaged instance group, please be aware that the order of NICs does matter. 
In particular, it's only possible to group VMs based on their primary NIC. Keep that in mind when grouping multiple VyOS instances into an unmanaged instance group.

## Organizational policies prerequisites
Some organizational policies might require an exception for this module to work.
For instance, the `constraints/storage.uniformBucketLevelAccess` constraint should not apply to the bucket where the configuration is held, as the current version of the module works with ACLs on single objects.
If you plan to use VyOS instance with a public IP assigned, you should make sure that the policy `constraints/compute.vmExternalIpAccess` does allow that.

Moreover, at the time of writing, the provided GCE VyOS image does not comply with shielded image requirements nor supports OS-LOGIN. 
Therefore `constraints/compute.requireShieldedVm` and `constraints/compute.requireOsLogin` org policies should allow an exception for the VyOS intance.

Lastly, the current version of the module assigns the "ip_forwardign" capability to the vyos instance, as it would be generally useful 
when using natting and firewalling capabilities of VyOS. Therefore, you should make sure the `constraints/compute.vmCanIpForward` 
organizational policy allows the VyOS instance to use the ip_forward functionality.


## Usage
Refer to the `example` folder for some quick examples on how to use this module.


## Module reference
### Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | n/a |

## Resources

| Name | Type |
|------|------|
| [google_compute_firewall.allow_ssh_iap](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_instance.vyos](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | resource |
| [google_project_iam_member.sa_log_writer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.sa_metric_writer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_service.project_services](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_pubsub_subscription.vyos_instance_subscription](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription) | resource |
| [google_pubsub_subscription_iam_policy.instance_subscriber](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription_iam_policy) | resource |
| [google_pubsub_topic.configuration_update_topic](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic) | resource |
| [google_pubsub_topic_iam_member.pubsub_notification_event](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic_iam_member) | resource |
| [google_service_account.vyos_compute_sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_storage_bucket.conf_file_bucket](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_iam_member.instance_sa_bucket_permissions](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [google_storage_bucket_object.conf_file_object](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |
| [google_storage_notification.configuration_update](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_notification) | resource |
| [google_compute_image.vyos](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image) | data source |
| [google_iam_policy.subscription_subscriber](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |
| [google_storage_project_service_account.gcs_account](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/storage_project_service_account) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_configuration_bucket_name"></a> [configuration\_bucket\_name](#input\_configuration\_bucket\_name) | Bucket name where to store VyOs instance configuration file | `any` | `null` | no |
| <a name="input_configuration_bucket_path"></a> [configuration\_bucket\_path](#input\_configuration\_bucket\_path) | GCS object path where to store VyOs instance configuration file | `any` | `null` | no |
| <a name="input_enable_serial_port_connection"></a> [enable\_serial\_port\_connection](#input\_enable\_serial\_port\_connection) | When true, allows the connection via the serial port | `bool` | `false` | no |
| <a name="input_gcp_region"></a> [gcp\_region](#input\_gcp\_region) | Default GCP region where to spawn resources | `any` | n/a | yes |
| <a name="input_instance_name"></a> [instance\_name](#input\_instance\_name) | Name to assign to the VyOs instance | `string` | `"vyos"` | no |
| <a name="input_instance_tags"></a> [instance\_tags](#input\_instance\_tags) | Tags to assign to the vyos instance | `list` | <pre>[<br>  "vyos"<br>]</pre> | no |
| <a name="input_instance_tier"></a> [instance\_tier](#input\_instance\_tier) | Machine tier for the VyOs instance | `string` | `"e2-small"` | no |
| <a name="input_instance_vyos_image_name"></a> [instance\_vyos\_image\_name](#input\_instance\_vyos\_image\_name) | Instance image name | `any` | n/a | yes |
| <a name="input_instance_vyos_image_project_id"></a> [instance\_vyos\_image\_project\_id](#input\_instance\_vyos\_image\_project\_id) | The project id where the vyos image is stored. Override this parameter if the image <br>    specified as instance\_vyos\_image\_name is located into another GCP project.<br>    When null, the project\_id value is used instead. | `any` | `null` | no |
| <a name="input_instance_zone"></a> [instance\_zone](#input\_instance\_zone) | GCP Zone where to spawn the VyOs instance | `any` | n/a | yes |
| <a name="input_networks_configuration"></a> [networks\_configuration](#input\_networks\_configuration) | Instance networking configuration. | <pre>map(object({<br>    assign_external_ip=bool,<br>    static_external_ip=string,<br>    create_iap_ssh_firewall_rule=bool,<br>    network_project_id=string,<br>    network=string,<br>    subnetwork=string,<br>    network_ip=string,<br>  }))</pre> | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Google project id where to spawn the VyOs instance | `any` | n/a | yes |
| <a name="input_user_data_content"></a> [user\_data\_content](#input\_user\_data\_content) | Holds the content of the user-data metadata to be used as configuration script at instance boot. | `string` | `""` | no |
| <a name="input_vyos_configuration_content"></a> [vyos\_configuration\_content](#input\_vyos\_configuration\_content) | Contents of the VyOs configuration to apply to the target instance | `any` | n/a | yes |

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

