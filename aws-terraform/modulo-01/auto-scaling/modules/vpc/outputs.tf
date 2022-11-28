output "main_vpc_id" {
    value = aws_vpc.main_vpc.id
}
output "web_public_subnet_id" {
    value = aws_subnet.web_public_subnet.id
}

output "bastion_public_subnet_id" {
    value = aws_subnet.bastion_public_subnet.id
}

output "vpc_cdir_block" {
    value = aws_vpc.main_vpc.cidr_block
}