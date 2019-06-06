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

module "stg" {
  source = "./environment"

  environment_name          = "stg"
  vpc_cidr_block            = "10.1.0.0/16"
  bastion_security_group_id = "${aws_security_group.bastion_sg.id}"

  ami_backend = "ami-062d483d60fe1b442"
  ami_db      = "ami-0af7311bae0e25887"

  key_name_backend = "UatPawrentsBackend"
  key_name_db      = "UatPawrentsDatabase"
}
