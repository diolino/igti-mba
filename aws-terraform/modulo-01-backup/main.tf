terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  region  = "us-east-1"
}

resource "aws_instance" "linux_web_server" {
  ami           = "ami-0224b73ead90b40d7" //AMI customizada Ubuntu Linux com Apache
  instance_type = "t3a.small"
  key_name = aws_key_pair.aws-key.id // associa keypair
  
  vpc_security_group_ids = [ "${module.security_group_linux_web_server.linux_web_server_sg_id}" ]
  tags = {
    Name = "EC2 Linux Web Server",
    Change = "True",
    Desliga = "True"
  }
}

resource "aws_instance" "win_web_server" {
  ami           = "ami-0fb5befc1450ca205"//AMI Windows
  instance_type = "t2.micro"
  key_name = aws_key_pair.aws-key.id // associa keypair
  vpc_security_group_ids = [ "${module.security_group_win_web_server.win_web_server_sg_id}" ]
  tags = {
    Name = "EC2 Win Web Server",
    Change = "True",
    Desliga = "True"
  }
}

resource "aws_eip" "linux_web_server_eip" {
  instance = aws_instance.linux_web_server.id
  vpc      = true
}
resource "aws_eip" "win_web_server_eip" {
  instance = aws_instance.win_web_server.id
  vpc      = true
}
// keypair
resource "aws_key_pair" "aws-key" {
  key_name   = "aws-key"
  public_key = file(var.PUBLIC_KEY_PATH)// Path is in the variables file
}

resource "aws_network_interface" "linux_ntw_interface" {
  subnet_id   = aws_subnet.public_subnet.id
  private_ips = ["172.16.10.100"]

  tags = {
    Name = "linux_ntw_interface"
  }
}

resource "aws_network_interface" "win_ntw_interface" {
  subnet_id   = aws_subnet.public_subnet.id
  private_ips = ["172.16.10.101"]

  tags = {
    Name = "win_ntw_interface"
  }
}

module "security_group_linux_web_server" {
  source = "./modules/sg-linux"
}
module "security_group_win_web_server" {
  source = "./modules/sg-windows"
}

module "main_vpc" {
  source = "./modules/vpc"
}

resource "aws_network_acl" "main" {
  # (resource arguments)
}