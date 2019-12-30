output "master_private_ip_addr" {
  value       = aws_instance.k8s-master-nodes.private_ip
  description = "The private IP address of the master server instance."
}