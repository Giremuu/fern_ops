###############################################################################
# outputs.tf
###############################################################################

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "sg_bastion_id" {
  value = aws_security_group.bastion.id
}

output "sg_nginx_id" {
  value = aws_security_group.nginx.id
}

output "sg_private_id" {
  value = aws_security_group.private.id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.this.id
}