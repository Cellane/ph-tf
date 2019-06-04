variable "environment_name" {
  description = "Name of the environment"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the environment’s VPC, should be /16 range"
}

variable "bastion_security_group_id" {
  description = "Security group in which bastion server is located"
}


variable "ami_backend" {
  description = "AMI to use for backend instance"
}

variable "ami_db" {
  description = "AMI to use for DB instance"
}

variable "instance_type_backend" {
  default     = "t2.small"
  description = "Instance type to use for backend instance"
}

variable "instance_type_db" {
  default     = "t2.small"
  description = "Instance type to use for DB instance"
}

variable "key_name_backend" {
  description = "Keypair name to use for backend instance"
}

variable "key_name_db" {
  description = "Keypair name to use for DB instance"
}
