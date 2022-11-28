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
  availability_zone = var.availability_zoneA
  map_public_ip_on_launch = true//auto-assign public IP - Isso que faz a subnet ser pública
  tags = {
    Name = "bastion_public-subnet"
  }

}

resource "aws_subnet" "app_private_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "172.16.12.0/24"
  availability_zone = var.availability_zoneB  
  tags = {
    Name = "app_private-subnet"
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

// associação da route table com a subnet pública para servidores bastion
resource "aws_route_table_association" "bastion_public_route_table_association" {
  subnet_id      = aws_subnet.bastion_public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

//NAT Gateway
resource "aws_nat_gateway" "nat_gateway_exit" {
  allocation_id = aws_eip.natgateway_eip.id
  # para permitir que as instâncias em uma subnet privada saiam usando o natgateway, 
  # o natgateway precisa estar em uma subnet pública
  subnet_id     = aws_subnet.bastion_public_subnet.id 
  tags = {
    Name = "nat_gateway_exit"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main_igw]
}

resource "aws_eip" "natgateway_eip" {
  vpc      = true
  tags = {
    Name = "natgateway_eip"
  }
}

//Route table para subnet privada
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main_vpc.id
  //route de saída pelo natgateway
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_exit.id //NAT Gateway
  }

  tags = {
    Name = "private_route_table"
  }
}

// associação da route tabel com a subnet privada de servidores de aplicação
resource "aws_route_table_association" "private_route_table_association" {
  subnet_id      = aws_subnet.app_private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

### NACL ####
# PROTEGE A SUBNET PÚBLICA DE SERVIDORES WEB
resource "aws_network_acl" "web_public_subnet_nacl" {
  vpc_id = aws_vpc.main_vpc.id
}
# PERMITE ENTRADA SSH APENAS PARA ORIGENS DENTRO DA VPC
resource "aws_network_acl_rule" "allow_ssh_in_vpc_for_web_public_subnet_rule" {
  network_acl_id = aws_network_acl.web_public_subnet_nacl.id
  rule_number    = 1
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = aws_vpc.main_vpc.cidr_block
  from_port        = 22
  to_port        = 22
}

# PERMITE ENTRADA HTTP PARA QULAQUER ORIGEM
resource "aws_network_acl_rule" "allow_http_for_web_public_subnet_from_everywhere_rule" {
  network_acl_id = aws_network_acl.web_public_subnet_nacl.id
  rule_number    = 2
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}
# PERMITE ENTRADA HTTPS PARA QULAQUER ORIGEM
resource "aws_network_acl_rule" "allow_https_for_web_public_subnet_from_everywhere_rule" {
  network_acl_id = aws_network_acl.web_public_subnet_nacl.id
  rule_number    = 3
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port =     443
  to_port        = 443
}
# PERMITE ENTRADA TCP PARA ephemeral ports
resource "aws_network_acl_rule" "allow_ephemeral_ports_for_web_public_subnet_from_everywhere_rule" {
  network_acl_id = aws_network_acl.web_public_subnet_nacl.id
  rule_number    = 4
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port =     32768
  to_port        = 61000
}

# PERMITE SAÍDA PARA QULAQUER DESTINO
resource "aws_network_acl_rule" "allow_exit_for_web_public_subnet_to_everywhere_rule" {
  network_acl_id = aws_network_acl.web_public_subnet_nacl.id
  rule_number    = 1
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
   from_port =     0
  to_port        = 0
}

resource "aws_network_acl_association" "acl_web_public_subnet_association" {
  network_acl_id = aws_network_acl.web_public_subnet_nacl.id
  subnet_id      = aws_subnet.web_public_subnet.id
}