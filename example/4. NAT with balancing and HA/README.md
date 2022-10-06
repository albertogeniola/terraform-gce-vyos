## Limitation
We use two ILBs for TCP and UDP traffic translation. The usage of a single ILB with shared IP is not supported on GCP when using custom routes
with an ILB as next hop: [Forwarding rules that use a common internal IP address (--purpose=SHARED_LOADBALANCER_VIP) are not supported.](https://cloud.google.com/load-balancing/docs/internal/ilb-next-hop-overview#additional_considerations)
