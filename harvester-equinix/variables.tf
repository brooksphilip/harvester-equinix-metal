variable "password" {
  type = string
}

variable "ssh_key" {
  type = string
}

variable "token" {
  type = string
}

variable "instance_size" {
  type = string
  default = "c3.medium.x86"
}

variable "metro" {
  type = string
  default = "ny"
}

variable "project" {
  type = string
  default = "Harvester"
}

variable "facility" {
  type = string
  default = "ny5"
}

variable "build_cluster" {
  type = bool
  default = "false"
}

variable "gateway_id" {
  
}
