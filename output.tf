output "dev_db_private_ip" {
  value = "${module.dev.db_private_ip}"
}

output "dev_backend_private_ip" {
  value = "${module.dev.backend_private_ip}"
}

output "dev_backend_public_ip" {
  value = "${module.dev.backend_public_ip}"
}
