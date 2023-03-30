output "ubuntu_password" {
  value = random_password.password
  sensitive = true
}

output "password" {
  value = random_password.password
  sensitive = true
}