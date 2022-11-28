terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.9.0"
    }
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  region  = var.region
}

resource "aws_instance" "linux_web_server" {
  ami           = "ami-0224b73ead90b40d7" //AMI customizada Ubuntu Linux com Apache
  instance_type = "t3a.medium"
  key_name = aws_key_pair.aws-key.id // associa keypair  
  subnet_id = module.main_vpc.web_public_subnet_id
  
  vpc_security_group_ids = [ "${module.security_group_linux_web_server.linux_web_server_sg_id}" ]
  

  /*network_interface {
    network_interface_id = aws_network_interface.linux_ntw_interface.id
    device_index         = 0
  }*/

  tags = {
    Name = "EC2 Linux Web Server",
    Change = "True",
    Desliga = "True"
  }
}

resource "aws_instance" "linux_bastion_server" {
  ami           = "ami-0224b73ead90b40d7" //AMI customizada Ubuntu Linux com Apache
  instance_type = "t3a.medium"
  key_name = aws_key_pair.aws-key.id // associa keypair  
  subnet_id = module.main_vpc.bastion_public_subnet_id
  
  vpc_security_group_ids = [ "${module.security_group_linux_web_server.linux_web_server_sg_id}" ]
  

  /*network_interface {
    network_interface_id = aws_network_interface.linux_ntw_interface.id
    device_index         = 0
  }*/

  tags = {
    Name = "EC2 Linux Bastion Server",
    Change = "True",
    Desliga = "True"
  }
}

resource "aws_instance" "linux_app_server" {
  ami           = "ami-0224b73ead90b40d7" //AMI customizada Ubuntu Linux com Apache
  instance_type = "t3a.medium"
  key_name = aws_key_pair.aws-key.id // associa keypair  
  subnet_id = module.main_vpc.app_private_subnet_id
  iam_instance_profile = module.iam_ec2_profile.ec2_semanager_profile_name
  vpc_security_group_ids = [ "${module.security_group_linux_web_server.linux_web_server_sg_id}" ]
  

  /*network_interface {
    network_interface_id = aws_network_interface.linux_ntw_interface.id
    device_index         = 0
  }*/

  tags = {
    Name = "EC2 Linux App Server",
    Change = "True",
    Desliga = "True"
  }
}

resource "aws_instance" "win_web_server" {
  ami           = "ami-0fb5befc1450ca205"//AMI Windows
  instance_type = "t2.micro"
  key_name = aws_key_pair.aws-key.id // associa keypair
  
  subnet_id = module.main_vpc.web_public_subnet_id
  
  vpc_security_group_ids = [ "${module.security_group_win_web_server.win_web_server_sg_id}" ]
  

  /*network_interface {
    network_interface_id = aws_network_interface.win_ntw_interface.id
    device_index         = 0
  }*/

  tags = {
    Name = "EC2 Win Web Server",
    Change = "True",
    Desliga = "True"
  }
}

/*resource "aws_eip" "linux_web_server_eip" {
  instance = aws_instance.linux_web_server.id
  vpc      = true
}
resource "aws_eip" "win_web_server_eip" {
  instance = aws_instance.win_web_server.id
  vpc      = true
}*/
// keypair
resource "aws_key_pair" "aws-key" {
  key_name   = "aws-key"
  public_key = file(var.PUBLIC_KEY_PATH)// Path is in the variables file
}

/*resource "aws_network_interface" "linux_ntw_interface" {
  subnet_id   = module.main_vpc.public_subnet_id
  private_ips = ["172.16.10.100"]

  tags = {
    Name = "linux_ntw_interface"
  }
}*/

/*resource "aws_network_interface" "win_ntw_interface" {
  subnet_id   = module.main_vpc.public_subnet_id
  private_ips = ["172.16.10.101"]

  tags = {
    Name = "win_ntw_interface"
  }
}*/

module "main_vpc" {
  source = "./modules/vpc"
}

module "security_group_linux_web_server" {
  source = "./modules/sg-linux"
 vpc_id = "${module.main_vpc.main_vpc_id}"
}
module "security_group_win_web_server" {
  source = "./modules/sg-windows"
  vpc_id = "${module.main_vpc.main_vpc_id}"
}
module "security_group_nfs" {
  source = "./modules/sg-nfs"
  vpc_id = "${module.main_vpc.main_vpc_id}"
  vpc_cdir_block = module.main_vpc.vpc_cdir_block
}

module "linux_web_server_ebs" {
  source = "./modules/ebs"
  ec2_id = aws_instance.linux_web_server.id
  availability_zone = var.availability_zone
}

module "linux_web_and_app_efs" {
  source = "./modules/efs"
  subnet_app_id = module.main_vpc.app_private_subnet_id
  subnet_web_id = module.main_vpc.web_public_subnet_id
  vpc_security_group_ids = module.security_group_nfs.nfs_sg_id
}

module "iam_ec2_profile" {
  source = "./modules/IAM"  
}

