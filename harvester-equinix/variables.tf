
variable "ssh_key" {

}

variable "instance_size" {
  default = "c3.medium.x86"

}

variable "metro" {
  default = "ny"
}

variable "project" {
  default = "Harvester"
}

variable "facility" {
  default = "ny5"
}

variable "build_cluster" {
  type = bool
  default = "false"
}

#DHCP

# variable plan {
#     default = "c3.small.x86"
# }

variable node_count {
    default = "1"
}

variable billing_cylce {
    default = "hourly"
}

// hostname_prefix defines the prefix for the DHCP server provisioned in equinix metal
variable hostname_prefix {
    default = "dhcp"
}

// vlan_id is the name of the harvester workload vlan
variable vlan_id {
    default = 100
}

#may need more than one ip block to get more than 256 ip's
variable public_ip_blocks {
    default = 1
}

// additional details are available here: https://metal.equinix.com/developers/docs/networking/metal-gateway/#ip-address-blocks-and-block-sizes
variable public_ip_block_size {
    default = "32"
}

variable "dns_server" {
  default = "1.1.1.1"
}

variable "cluster_registration_url" {
}