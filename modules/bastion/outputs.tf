output "bastion_private_ip_addr" {
  value       = aws_instance.bastion-ec2.private_ip
  description = "The private IP address of the bastion instance."
}
output "bastion_public_ip_addr" {
  value       = aws_instance.bastion-ec2.public_ip
  description = "The public IP address of the bastion instance."
}