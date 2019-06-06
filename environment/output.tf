######
### OUTPUTS
######

output "db_private_ip" {
  value = "${aws_instance.instance_db.private_ip}"
}

output "backend_private_ip" {
  value = "${aws_instance.instance_backend.private_ip}"
}

output "backend_public_ip" {
  value = "${aws_eip.eip_backend.public_ip}"
}
