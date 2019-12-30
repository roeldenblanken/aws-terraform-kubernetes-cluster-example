# NOTE: This is the environment definition that will be used by all environments.
# The actual environments (like dev) just inject their environment dependent values
# to this env-def module which defines the actual environment and creates that environment
# by injecting the environment related values to modules.


# NOTE: In demonstration you might want to follow this procedure since there is some dependency
# for the ECR.
# 1. Comment all other modules except ECR.
# 2. Run terraform init and apply. This creates only the ECR.
# 3. Use script 'tag-and-push-to-ecr.sh' to deploy the application Docker image to ECR.
# 3. Uncomment all modules.
# 4. Run terraform init and apply. This creates other resources and also deploys the Kubernetes nodes using the image in Docker Hub.
# NOTE: In real world development we wouldn't need that procedure, of course, since the ECR registry would be created
# at the beginning of the project and the ECR registry would then persist for the development period for that
# environment.


locals {
  my_name  = "${var.prefix}-${var.env}"
  my_env   = "${var.prefix}-${var.env}"
}


# We need aws account id.
data "aws_caller_identity" "current" {}


# You can use Resource groups to find resources. See AWS Console => Resource Groups => Saved.
module "resource-groups" {
  source           = "../resource-groups"
  prefix           = "${var.prefix}"
  env              = "${var.env}"
  region           = "${var.region}"
}

# We could run the demo in default vpc but it is a good idea to isolate
# even small demos to a dedicated vpc.
module "vpc" {
  source                = "../vpc"
  prefix                = "${var.prefix}"
  env                   = "${var.env}"
  region                = "${var.region}"
  vpc_cidr_block        = "${var.vpc_cidr_block}"
  private_subnet_count  = "${var.private_subnet_count}"
  app_port              = "8080"
  database_port         = "${var.database_port}"
  admin_workstation_ip  = "${var.admin_workstation_ip}"
}

# This is the actual bastion module which creates bastion host
# to expose the bastion to the internet.
module "bastion" {
  source                       = "../bastion"
  prefix                       = "${var.prefix}"
  env                          = "${var.env}"
  region                       = "${var.region}"
  public_subnet_ids            = "${module.vpc.public_subnet_ids}"
  bastion-public-subnet_sg_id  = "${module.vpc.bastion_public_subnet_sg_id}"
}

# This is the actual RDS module which creates the database
module "rds" {
  source                       = "../rds"
  prefix                       = "${var.prefix}"
  env                          = "${var.env}"
  region                       = "${var.region}"
  private_subnet_az_names  	   = "${module.vpc.private_subnet_availability_zones}"
  private_subnet_ids       	   = "${module.vpc.private_subnet_ids}"
  vpc_id                       = "${module.vpc.vpc_id}"
  aws_account_id               = "${data.aws_caller_identity.current.account_id}"
  database_private_subnet_sg_id= "${module.vpc.database_private_subnet_sg_id}"
  database_name     		   = "${var.database_name}"
  database_user 			   = "${var.database_user}"
  database_password 		   = "${var.database_password}"
  database_port                = "${var.database_port}"
}

# This is the actual kubernetes master nodes module which creates master nodes
module "master-nodes" {
  source                       			= "../k8s-master-nodes"
  prefix                       			= "${var.prefix}"
  env                          			= "${var.env}"
  region                       			= "${var.region}"
  master_instance_type	    		    = var.master_instance_type
  private_subnet_ids            		= "${module.vpc.private_subnet_ids}"
  k8s-master-nodes-private-subnet_sg_id = "${module.vpc.k8s_master_nodes_private_subnet_sg_id}"
}

# This is the actual kubernetes worker nodes module which creates worker nodes
# Depends on the master node module
module "worker-nodes" {
  source                       			= "../k8s-worker-nodes"
  prefix                       			= "${var.prefix}"
  env                          			= "${var.env}"
  region                       			= "${var.region}"
  worker_instance_type	    		    = var.worker_instance_type
  private_subnet_ids            		= "${module.vpc.private_subnet_ids}"
  k8s-worker-nodes-private-subnet_sg_id = "${module.vpc.k8s_worker_nodes_private_subnet_sg_id}"
  aws_account_id               			= "${data.aws_caller_identity.current.account_id}"
  master_private_ip_addr				= module.master-nodes.master_private_ip_addr
  asg_worker_nodes_min_size	   			= var.asg_worker_nodes_min_size
  asg_worker_nodes_max_size	    	 	= var.asg_worker_nodes_max_size
}
