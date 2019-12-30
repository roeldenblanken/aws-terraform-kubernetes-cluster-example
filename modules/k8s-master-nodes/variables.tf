variable "prefix" {}
variable "env" {}
variable "region" {}
variable "k8s-master-nodes-private-subnet_sg_id" {}
	
variable "private_subnet_ids" {
  type = list
}

variable "master_instance_type" {}
