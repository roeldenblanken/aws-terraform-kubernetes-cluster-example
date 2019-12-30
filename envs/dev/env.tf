# Dev environment.
# NOTE: If environment copied, change environment related values (e.g. "dev" -> "perf").

##### Terraform configuration #####

# Usage:
# AWS_PROFILE=default terraform init
# AWS_PROFILE=default terraform get
# AWS_PROFILE=default terraform plan
# AWS_PROFILE=default terraform apply

# NOTE: If you want to create a separate version of this demo, use a unique prefix, e.g. "myname-kubernetes-demo".
# This way all entities have a different name and also you create a dedicate terraform state file
# (remember to call 'terraform destroy' once you are done with your experimentation).
# So, you have to change the prefix in both local below and terraform configuration section in key.

locals {
  # Ireland
  my_region                 = "eu-west-1"
  # Use unique environment names, e.g. dev, custqa, qa, test, perf, ci, prod...
  my_env                    = "dev"
  # Use consistent prefix, e.g. <cloud-provider>-<demo-target/purpose>-demo, e.g. aws-kubernetes-demo
  my_prefix                 = "kubernetes-demo"
  all_demos_terraform_info  = "blankia-demo"
  # NOTE: Reserve 10.20.*.* address space for this demonstration.
  vpc_cidr_block            = "10.20.0.0/16"
  private_subnet_count      = "2"
  app_port                  = "8080"
  database_name     		= "databaseblankia"
  database_user 			= "admin"
  database_port             = "3306"
  bastion_instance_size 	= "t2.medium"
  master_instance_type	    = "t2.medium"
  worker_instance_type	    = "t2.medium"
  asg_worker_nodes_min_size	= 1
  asg_worker_nodes_max_size	= 2
}

# NOTE: You cannot use locals in the terraform configuration since terraform
# configuration does not allow interpolation in the configuration section.
terraform {
  required_version = ">=0.12.18"
  backend "s3" {
    # NOTE: We use the same bucket for storing terraform statefiles for all PC demos (but different key).
    bucket     = "terraform-blankia"
    # NOTE: This must be unique for each demo!!!
    # Use the same prefix and dev as in local!
    # I.e. key = "<prefix>/<dev>/terraform.tfstate".
    key        = "aws-kubernetes-demo/dev/terraform.tfstate"
    region     = "eu-west-1"
    # NOTE: We use the same DynamoDB table for locking all state files of all demos. Do not change name.
    dynamodb_table = "blankia-demos-terraform-backends"
    # NOTE: This is AWS account profile, not env! You probably have two accounts: one dev (or test) and one prod.
    profile    = "default"
  }
}

provider "aws" {
  region     = local.my_region
}

# Admin workstation ip, must be injected with
# export TF_VAR_admin_workstation_ip="11.11.11.11/32"
variable "admin_workstation_ip" {}

data "aws_ssm_parameter" "DB_PASSWORD" {
  name = "DB_PASSWORD"
}

# Here we inject our values to the environment definition module which creates all actual resources.
module "env-def" {
  source                    = "../../modules/env-def"
  prefix                    = "${local.my_prefix}"
  env                       = "${local.my_env}"
  region                    = "${local.my_region}"
  vpc_cidr_block            = "${local.vpc_cidr_block}"
  private_subnet_count      = "${local.private_subnet_count}"
  admin_workstation_ip      = "${var.admin_workstation_ip}"
  database_name     		= "${local.database_name}"
  database_user 			= "${local.database_user}"
  database_password 		= data.aws_ssm_parameter.DB_PASSWORD.value
  database_port             = "${local.database_port}"
  bastion_instance_size		= "${local.bastion_instance_size}"
  master_instance_type		= "${local.master_instance_type}"
  worker_instance_type		= "${local.worker_instance_type}" 
  asg_worker_nodes_min_size	= "${local.asg_worker_nodes_min_size}"
  asg_worker_nodes_max_size	= "${local.asg_worker_nodes_max_size}"
}
