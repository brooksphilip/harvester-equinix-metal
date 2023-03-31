output "ubuntu_password" {
  value = random_password.password
  sensitive = true
}

output "harvester_password" {
  value = random_password.password
  sensitive = true
}

output "token" {
  value = random_password.token
  sensitive = true
}