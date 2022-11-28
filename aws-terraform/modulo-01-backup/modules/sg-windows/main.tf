resource "aws_security_group" "win_web_server_sg" {
  name    = "win_web_server_sg"
}

############ Inbound Rules ############
resource "aws_security_group_rule" "win_web_server_sg_inbound_80" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.win_web_server_sg.id
}

resource "aws_security_group_rule" "win_web_server_sg_inbound_443" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.win_web_server_sg.id
}

resource "aws_security_group_rule" "win_web_server_sg_inbound_3389" {
  type              = "ingress"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.win_web_server_sg.id
}

############ Outbound Rules ############
resource "aws_security_group_rule" "win_web_server_sg_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.win_web_server_sg.id
}