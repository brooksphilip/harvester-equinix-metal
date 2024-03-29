terraform {
  required_providers {
    equinix = {
      source = "equinix/equinix"
      #   version = "1.13.0"
    }
  }
}

provider "equinix" {
  #   client_id     = "someEquinixAPIClientID"
  #   client_secret = "someEquinixAPIClientSecret"
  auth_token = var.auth_token
}

module "harvester1" {
  source   = "./harvester-equinix"
  project = "Harvester_Terraform"
  ssh_key  = var.ssh_key
  public_ip_block_size = 16
  instance_size = "m3.small.x86"
  # instance_size = "" #over write instance size default
  ##enabling this will deploy a 3 node cluster (Default False)
  build_cluster = true
  cluster_registration_url = var.cluster_registration_url
}

output "password" {
  value = module.harvester1.ubuntu_password
  sensitive = true
}

output "harvester_password" {
  value = module.harvester1.harvester_password
  sensitive = true
}

output "token" {
  value = module.harvester1.token
  sensitive = true
}