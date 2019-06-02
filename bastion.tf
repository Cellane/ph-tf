resource "aws_default_vpc" "default_vpc" {
}

resource "aws_security_group" "bastion_sg" {
  name   = "bastion"
  vpc_id = "${aws_default_vpc.default_vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["103.208.220.133/32"]
  }
}

resource "aws_security_group_rule" "bastion_sg_rule_dev_db_ssh" {
  security_group_id        = "${aws_security_group.bastion_sg.id}"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  type                     = "egress"
  source_security_group_id = "${aws_security_group.dev_sg_db_private.id}"
}

resource "aws_security_group_rule" "bastion_sg_rule_dev_dev_mysql" {
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

  tags {
    Name = "bastion"
  }
}
