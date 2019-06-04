module "dev" {
  source = "./environment"

  environment_name          = "dev"
  vpc_cidr_block            = "10.0.0.0/16"
  bastion_security_group_id = "${aws_security_group.bastion_sg.id}"

  ami_backend = "ami-091830e484c3984fa"
  ami_db      = "ami-01a74235d69740cfa"

  key_name_backend = "DevBackendApp"
  key_name_db      = "DevPawrentsDatabase"
}
