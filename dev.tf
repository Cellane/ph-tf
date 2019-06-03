resource "aws_vpc" "dev_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "dev_subnet_public" {
  cidr_block              = "${cidrsubnet(aws_vpc.dev_vpc.cidr_block, 8, 1)}"
  map_public_ip_on_launch = true
  vpc_id                  = "${aws_vpc.dev_vpc.id}"
}

resource "aws_subnet" "dev_subnet_private" {
  cidr_block = "${cidrsubnet(aws_vpc.dev_vpc.cidr_block, 8, 2)}"
  vpc_id     = "${aws_vpc.dev_vpc.id}"
}

resource "aws_security_group" "dev_sg_db_private" {
  name   = "dev-db-private"
  vpc_id = "${aws_vpc.dev_vpc.id}"

  ingress {
    description     = "MySQL to bastion"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.bastion_sg.id}"]
  }
}

resource "aws_security_group" "dev_sg_backend_public" {
  name   = "dev-backend-public"
  vpc_id = "${aws_vpc.dev_vpc.id}"

  ingress {
    description = "HTTP to external world"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS to external world"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "dev_instance_db" {
  ami                    = "ami-01a74235d69740cfa"
  instance_type          = "t2.small"
  vpc_security_group_ids = ["${aws_security_group.dev_sg_db_private.id}"]
  subnet_id              = "${aws_subnet.dev_subnet_private.id}"

  tags = {
    Name = "dev-db"
  }
}

resource "aws_instance" "dev_instance_backend" {
  ami                    = "ami-091830e484c3984fa"
  instance_type          = "t2.small"
  vpc_security_group_ids = ["${aws_security_group.dev_sg_backend_public.id}"]
  subnet_id              = "${aws_subnet.dev_subnet_public.id}"

  tags = {
    Name = "dev-backend"
  }
}

resource "aws_eip" "dev_eip_backend" {
  instance = "${aws_instance.dev_instance_backend.id}"
}
