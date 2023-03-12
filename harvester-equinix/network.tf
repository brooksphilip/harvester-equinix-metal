
# resource "equinix_metal_vlan" "harvester" {
#   description = "Harvester-VLAN"
#   metro       = var.metro
#   project_id  = equinix_metal_project.project.id
# }

# resource "equinix_metal_gateway" "harvester" {
#   project_id               = equinix_metal_project.project.id
#   vlan_id                  = equinix_metal_vlan.harvester.id
#   private_ipv4_subnet_size = 4
# }

# resource "equinix_metal_vlan" "harvester" {
#   description = "Harvester-VLAN"
#   metro       = var.metro
#   project_id  = equinix_metal_project.project.id
#   vxlan       = 2
# }

data "equinix_metal_gateway" "harvester" {
  gateway_id = var.gateway_id
}


# resource "equinix_metal_vlan" "harvester" {
#   project_id = var.project
#   metro = var.metro
#   vxlan = 2
# }

# data "equinix_metal_vlan" "harvester" {
#   vlan_id = equinix_metal_vlan.harvester.id
# }
  

data "equinix_metal_vlan" "harvester" {
  project_id = data.equinix_metal_project.project.id
  vxlan      = 2
  metro      = var.metro
}
