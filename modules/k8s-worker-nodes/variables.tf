variable "prefix" {}
variable "env" {}
variable "region" {}
variable "k8s-worker-nodes-private-subnet_sg_id" {}
	
variable "private_subnet_ids" {
  type = list
}
variable "aws_account_id" {}
variable "master_private_ip_addr" {}
variable "worker_instance_type" {}
variable "asg_worker_nodes_min_size" {}
variable "asg_worker_nodes_max_size" {}
