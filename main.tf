terraform {
  required_providers {
    equinix = {
      source = "equinix/equinix"
      #   version = "1.13.0"
    }
  }
  backend "s3" {
    bucket = "philiprgsterraform"
    region = "us-east-1"
    key    = "equinix-metal/terraform.tfstate"
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
  password = var.password
  ssh_key  = var.ssh_key
  #k8s join token
  token    = var.token
  ##enabling this will deploy a 3 node cluster (Default False)
  build_cluster = true
}