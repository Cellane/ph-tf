output "dev_db_private_ip" {
  value = "${module.dev.db_private_ip}"
}

output "dev_backend_private_ip" {
  value = "${module.dev.backend_private_ip}"
}

output "dev_backend_public_ip" {
  value = "${module.dev.backend_public_ip}"
}

output "stg_db_private_ip" {
  value = "${module.stg.db_private_ip}"
}

output "stg_backend_private_ip" {
  value = "${module.stg.backend_private_ip}"
}

output "stg_backend_public_ip" {
  value = "${module.stg.backend_public_ip}"
}

output "prod_db_private_ip" {
  value = "${module.prod.db_private_ip}"
}

output "prod_backend_private_ip" {
  value = "${module.prod.backend_private_ip}"
}

output "prod_backend_public_ip" {
  value = "${module.prod.backend_public_ip}"
}
