variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "vpc_cdir_block" {
  description = "vpc_cdir_block"
  type        = string
}

resource "aws_security_group" "nfs_sg" {
  name    = "nfs_sg"
  vpc_id = var.vpc_id
}

############ Inbound Rules ############
resource "aws_security_group_rule" "nfs_sg_inbound_80" {
  type              = "ingress"
  from_port         = 2049 // * SG é stateful (liberando porta de entrada, automaticamente libera saída).
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cdir_block]
  security_group_id = aws_security_group.nfs_sg.id
}