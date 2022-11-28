variable "ec2_id" {
  description = "EC2_ID"
  type        = string
}
variable "availability_zone" {
  description = "availability_zone"
  type        = string
  default = "us-east-1a"
}

resource "aws_ebs_volume" "linux_web_server_ebs" {
  availability_zone = var.availability_zone
  size              = 1
}

resource "aws_volume_attachment" "linux_web_server_ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.linux_web_server_ebs.id
  instance_id = var.ec2_id
}

// Como automatizar a montagem no servidos?
// Como criar um para cada servidor de forma dinâmica?
// Como criar em ambientes escaláveis?