variable "prefix" {}
variable "env" {}
variable "region" {}
variable "bastion_instance_size" {}
variable "bastion-public-subnet_sg_id" {}
variable "master_private_ip_addr" {}
variable "public_subnet_ids" {
  type = list
}
variable "k8s_deployer_lambda_name" {}
variable "k8s_deployer_lambda_arn" {}
variable "k8s_deployer_lambda_python_run_time"{}
