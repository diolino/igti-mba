//VPC
resource "aws_vpc" "main_vpc" {
  cidr_block       = "172.16.0.0/16"
  instance_tenancy = "default"
  
  tags = {
    Name = "main_vpc"
  }
}

//Subnet Pública para servidores web
resource "aws_subnet" "web_public_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = var.availability_zoneA
  map_public_ip_on_launch = true//auto-assign public IP - Isso que faz a subnet ser pública
  tags = {
    Name = "web_public-subnet"
  }

}

//Subnet Pública para servidores bastion
resource "aws_subnet" "bastion_public_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "172.16.11.0/24"
  availability_zone = var.availability_zoneB
  map_public_ip_on_launch = true//auto-assign public IP - Isso que faz a subnet ser pública
  tags = {
    Name = "bastion_public-subnet"
  }

}

//Internet Gateway para a VPC
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main_igw"
  }
}
//Route table para subnet pública
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id
  //route de entrada e saída pelo internet gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "public_route_table"
  }
}
// associação da route tabel com a subnet pública para servidores web
resource "aws_route_table_association" "web_public_route_table_association" {
  subnet_id      = aws_subnet.web_public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}