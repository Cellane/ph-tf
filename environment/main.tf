######
### VPCS
######

data "aws_vpc" "default" {
  default = true
}

resource "aws_vpc" "vpc" {
  cidr_block = "${var.vpc_cidr_block}"

  tags = {
    Name = "${var.environment_name}-vpc"
  }
}

######
### VPC PEERING CONNECTIONS
######

resource "aws_vpc_peering_connection" "peering_to_bastion" {
  vpc_id      = "${aws_vpc.vpc.id}"
  peer_vpc_id = "${data.aws_vpc.default.id}"
  auto_accept = true

  tags = {
    Name = "${var.environment_name}-to-bastion-peering"
  }
}

######
### SUBNETS
######

resource "aws_subnet" "subnet_public" {
  cidr_block              = "${cidrsubnet(aws_vpc.vpc.cidr_block, 8, 0)}"
  map_public_ip_on_launch = true
  vpc_id                  = "${aws_vpc.vpc.id}"

  tags = {
    Name = "${var.environment_name}-subnet-public"
  }
}

resource "aws_subnet" "subnet_private" {
  cidr_block = "${cidrsubnet(aws_vpc.vpc.cidr_block, 8, 1)}"
  vpc_id     = "${aws_vpc.vpc.id}"

  tags = {
    Name = "${var.environment_name}-subnet-private"
  }
}

#####
### INTERNET GATEWAYS
######

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name = "{var.environment_name}-internet-gateway"
  }
}

######
### ROUTE TABLES
######

data "aws_route_table" "default" {
  vpc_id = "${data.aws_vpc.default.id}"
}

resource "aws_route_table" "route_table_private" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name = "{var.environment_name}-route-table-private"
  }
}

resource "aws_route_table" "route_table_public" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name = "{var.environment_name}-route-table-public"
  }
}

######
### ROUTE TABLE ASSOCIATIONS
######

resource "aws_route_table_association" "route_table_private" {
  route_table_id = "${aws_route_table.route_table_private.id}"
  subnet_id      = "${aws_subnet.subnet_private.id}"
}

resource "aws_route_table_association" "route_table_public" {
  route_table_id = "${aws_route_table.route_table_public.id}"
  subnet_id      = "${aws_subnet.subnet_public.id}"
}

######
### ROUTES
######

resource "aws_route" "route_from_bastion" {
  route_table_id            = "${data.aws_route_table.default.id}"
  destination_cidr_block    = "${aws_vpc.vpc.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peering_to_bastion.id}"
}

resource "aws_route" "private_route_to_bastion" {
  route_table_id            = "${aws_route_table.route_table_private.id}"
  destination_cidr_block    = "${data.aws_vpc.default.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peering_to_bastion.id}"
}

resource "aws_route" "public_route_to_bastion" {
  route_table_id            = "${aws_route_table.route_table_public.id}"
  destination_cidr_block    = "${data.aws_vpc.default.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peering_to_bastion.id}"
}

resource "aws_route" "backend_to_internet" {
  route_table_id         = "${aws_route_table.route_table_public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.internet_gateway.id}"
}

######
### SECURITY GROUPS
######

resource "aws_security_group" "db_private" {
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${var.bastion_security_group_id}"]
  }

  ingress {
    description     = "MySQL from bastion"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${var.bastion_security_group_id}"]
  }

  ingress {
    description     = "MySQL from backend"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.backend_public.id}"]
  }

  tags = {
    Name = "${var.environment_name}-db-private-sg"
  }
}

resource "aws_security_group" "backend_public" {
  vpc_id = "${aws_vpc.vpc.id}"

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

  ingress {
    description = "HTTP to external world (8080)"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${var.bastion_security_group_id}"]
  }

  tags = {
    Name = "${var.environment_name}-backend-public-sg"
  }
}

######
### SECURITY GROUP RULES
######

resource "aws_security_group_rule" "backend_mysql_to_db" {
  description              = "MySQL to ${var.environment_name} DB"
  security_group_id        = "${aws_security_group.backend_public.id}"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  type                     = "egress"
  source_security_group_id = "${aws_security_group.db_private.id}"
}

resource "aws_security_group_rule" "bastion_ssh_to_db" {
  description              = "SSH to ${var.environment_name} DB"
  security_group_id        = "${var.bastion_security_group_id}"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  type                     = "egress"
  source_security_group_id = "${aws_security_group.db_private.id}"
}

resource "aws_security_group_rule" "bastion_mysql_to_db" {
  description              = "MySQL to ${var.environment_name} DB"
  security_group_id        = "${var.bastion_security_group_id}"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  type                     = "egress"
  source_security_group_id = "${aws_security_group.db_private.id}"
}

resource "aws_security_group_rule" "bastion_ssh_to_backend" {
  description              = "SSH to ${var.environment_name} backend"
  security_group_id        = "${var.bastion_security_group_id}"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  type                     = "egress"
  source_security_group_id = "${aws_security_group.backend_public.id}"
}

######
### INSTANCES
######

resource "aws_instance" "instance_db" {
  ami                    = "${var.ami_db}"
  instance_type          = "${var.instance_type_db}"
  key_name               = "${var.key_name_db}"
  private_ip             = "${cidrhost(aws_subnet.subnet_private.cidr_block, 16)}"
  vpc_security_group_ids = ["${aws_security_group.db_private.id}"]
  subnet_id              = "${aws_subnet.subnet_private.id}"

  tags = {
    Name = "${var.environment_name}-db"
  }
}

resource "aws_instance" "instance_backend" {
  ami                    = "${var.ami_backend}"
  instance_type          = "${var.instance_type_backend}"
  key_name               = "${var.key_name_backend}"
  private_ip             = "${cidrhost(aws_subnet.subnet_public.cidr_block, 16)}"
  vpc_security_group_ids = ["${aws_security_group.backend_public.id}"]
  subnet_id              = "${aws_subnet.subnet_public.id}"

  tags = {
    Name = "${var.environment_name}-backend"
  }
}

######
### ELASTIC IPS
######

resource "aws_eip" "eip_backend" {
  instance = "${aws_instance.instance_backend.id}"

  tags = {
    Name = "${var.environment_name}-backend-ip"
  }
}
