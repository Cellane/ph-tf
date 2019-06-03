######
### VPCS
######

resource "aws_vpc" "dev_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "dev-vpc"
  }
}

######
### VPC PEERING CONNECTIONS
######

resource "aws_vpc_peering_connection" "dev_to_bastion_peering" {
  vpc_id      = "${aws_vpc.dev_vpc.id}"
  peer_vpc_id = "${data.aws_vpc.default.id}"
  auto_accept = true

  tags = {
    Name = "dev-to-bastion-peering"
  }
}

######
### SUBNETS
######

resource "aws_subnet" "dev_subnet_public" {
  cidr_block              = "${cidrsubnet(aws_vpc.dev_vpc.cidr_block, 8, 1)}"
  map_public_ip_on_launch = true
  vpc_id                  = "${aws_vpc.dev_vpc.id}"

  tags = {
    Name = "dev-public-subnet"
  }
}

resource "aws_subnet" "dev_subnet_private" {
  cidr_block = "${cidrsubnet(aws_vpc.dev_vpc.cidr_block, 8, 2)}"
  vpc_id     = "${aws_vpc.dev_vpc.id}"

  tags = {
    Name = "dev-private-subnet"
  }
}

#####
### INTERNET GATEWAYS
######

resource "aws_internet_gateway" "dev_internet_gateway" {
  vpc_id = "${aws_vpc.dev_vpc.id}"

  tags = {
    Name = "dev-internet-gateway"
  }
}

######
### ROUTE TABLES
######

resource "aws_route_table" "dev_route_table_private" {
  vpc_id = "${aws_vpc.dev_vpc.id}"

  tags = {
    Name = "dev-route-table-private"
  }
}


resource "aws_route_table" "dev_route_table_public" {
  vpc_id = "${aws_vpc.dev_vpc.id}"

  tags = {
    Name = "dev-route-table-public"
  }
}

######
### ROUTE TABLE ASSOCIATIONS
######

resource "aws_route_table_association" "dev_route_table_private" {
  route_table_id = "${aws_route_table.dev_route_table_private.id}"
  subnet_id      = "${aws_subnet.dev_subnet_private.id}"
}


resource "aws_route_table_association" "dev_route_table_public" {
  route_table_id = "${aws_route_table.dev_route_table_public.id}"
  subnet_id      = "${aws_subnet.dev_subnet_public.id}"
}

######
### ROUTES
######

resource "aws_route" "dev_route_from_bastion" {
  route_table_id            = "${data.aws_route_table.default.id}"
  destination_cidr_block    = "${aws_vpc.dev_vpc.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.dev_to_bastion_peering.id}"
}

resource "aws_route" "dev_private_route_to_bastion" {
  route_table_id            = "${aws_route_table.dev_route_table_private.id}"
  destination_cidr_block    = "${data.aws_vpc.default.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.dev_to_bastion_peering.id}"
}

resource "aws_route" "dev_public_route_to_bastion" {
  route_table_id            = "${aws_route_table.dev_route_table_public.id}"
  destination_cidr_block    = "${data.aws_vpc.default.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.dev_to_bastion_peering.id}"
}

resource "aws_route" "dev_backend_to_internet" {
  route_table_id         = "${aws_route_table.dev_route_table_public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.dev_internet_gateway.id}"
}

######
### SECURITY GROUPS
######

resource "aws_security_group" "dev_sg_db_private" {
  name   = "dev-db-private"
  vpc_id = "${aws_vpc.dev_vpc.id}"

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.bastion_sg.id}"]
  }

  ingress {
    description     = "MySQL from bastion"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.bastion_sg.id}"]
  }

  ingress {
    description     = "MySQL from backend"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.dev_sg_backend_public.id}"]
  }

  tags = {
    Name = "dev-db-private-sg"
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

  tags = {
    Name = "dev-backend-public-sg"
  }
}

######
### SECURITY GROUP RULES
######

resource "aws_security_group_rule" "dev_sg_rule_backend_mysql_to_db" {
  description              = "MySQL to dev DB"
  security_group_id        = "${aws_security_group.dev_sg_backend_public.id}"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  type                     = "egress"
  source_security_group_id = "${aws_security_group.dev_sg_db_private.id}"
}

######
### INSTANCES
######

resource "aws_instance" "dev_instance_db" {
  ami                    = "ami-01a74235d69740cfa"
  instance_type          = "t2.small"
  key_name               = "DevPawrentsDatabase"
  vpc_security_group_ids = ["${aws_security_group.dev_sg_db_private.id}"]
  subnet_id              = "${aws_subnet.dev_subnet_private.id}"

  tags = {
    Name = "dev-db"
  }
}

resource "aws_instance" "dev_instance_backend" {
  ami                    = "ami-091830e484c3984fa"
  instance_type          = "t2.small"
  key_name               = "DevBackendApp"
  vpc_security_group_ids = ["${aws_security_group.dev_sg_backend_public.id}"]
  subnet_id              = "${aws_subnet.dev_subnet_public.id}"

  tags = {
    Name = "dev-backend"
  }
}

######
### ELASTIC IPS
######

resource "aws_eip" "dev_eip_backend" {
  instance = "${aws_instance.dev_instance_backend.id}"

  tags = {
    Name = "dev-backend-ip"
  }
}

######
### OUTPUTS
######

output "dev_db_private_ip" {
  value = "${aws_instance.dev_instance_db.private_ip}"
}

output "dev_backend_public_ip" {
  value = "${aws_eip.dev_eip_backend.public_ip}"
}
