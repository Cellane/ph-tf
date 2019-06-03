resource "aws_default_vpc" "default" {
}

resource "aws_security_group" "bastion_sg" {
  name   = "bastion"
  vpc_id = "${aws_default_vpc.default.id}"

  ingress {
    description = "SSH from allowed IP addresses"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      "103.208.220.0/24" # VPN
    ]
  }
}

resource "aws_security_group_rule" "bastion_sg_rule_dev_db_ssh" {
  description              = "SSH to dev DB"
  security_group_id        = "${aws_security_group.bastion_sg.id}"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  type                     = "egress"
  source_security_group_id = "${aws_security_group.dev_sg_db_private.id}"
}

resource "aws_security_group_rule" "bastion_sg_rule_dev_dev_mysql" {
  description              = "MySQL to dev DB"
  security_group_id        = "${aws_security_group.bastion_sg.id}"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  type                     = "egress"
  source_security_group_id = "${aws_security_group.dev_sg_db_private.id}"
}

resource "aws_instance" "bastion_instance" {
  ami                    = "${data.aws_ami.ubuntu.id}"
  instance_type          = "t2.micro"
  key_name               = "DevStgBastion"
  vpc_security_group_ids = ["${aws_security_group.bastion_sg.id}"]

  tags = {
    Name = "bastion"
  }
}
