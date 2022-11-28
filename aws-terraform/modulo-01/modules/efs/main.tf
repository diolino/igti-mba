variable "subnet_web_id" {
  description = "subnet_web"
  type        = string
}

variable "subnet_app_id" {
  description = "subnet_web"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "subnet_web"  
}

resource "aws_efs_file_system" "linux_web_and_app_efs" {
  creation_token = "linux-web-and-app-efs"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "linux-web-and-app-efs"
  }
}

resource "aws_efs_mount_target" "mount-subnet-web" {
  file_system_id = aws_efs_file_system.linux_web_and_app_efs.id
  subnet_id      = var.subnet_web_id
  security_groups = [ var.vpc_security_group_ids ]
}

resource "aws_efs_mount_target" "mount-subnet-app" {
    file_system_id = aws_efs_file_system.linux_web_and_app_efs.id
    subnet_id      = var.subnet_app_id
    security_groups = [ var.vpc_security_group_ids ]
}

//Como fazer a montagem de forma automatizada?
//Como criar mount_target para uma sério de subnets?