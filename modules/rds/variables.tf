variable "prefix" {}
variable "env" {}
variable "region" {}
variable "private_subnet_az_names" {}
variable "private_subnet_ids" {
  type = list
}
variable "vpc_id" {}
variable "aws_account_id" {}
variable "database_private_subnet_sg_id" {}
variable "database_name" {}
variable "database_user" {}
variable "database_password" {}
variable "database_port"{}