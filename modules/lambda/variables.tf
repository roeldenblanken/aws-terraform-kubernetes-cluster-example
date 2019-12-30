variable "prefix" {}
variable "env" {}
variable "region" {}
variable "vpc_id" {}
variable "k8s-deployer-lambda-private-subnet_sg_id" {}
variable "private_subnet_ids" {
  type = list
}
variable "aws_account_id" {}
variable "bastion_host" {}
variable "master_private_ip_addr" {}
variable "k8s_deployer_lambda_python_run_time" {}

