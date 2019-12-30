locals {
  my_name       = "${var.prefix}-${var.env}-k8s-worker-nodes"
  my_deployment = "${var.prefix}-${var.env}"
  my_key_name   = "Work"
}

resource "aws_iam_instance_profile" "k8s-worker-nodes-profile" {
  name = "k8s-worker-nodes-profile"
  role = aws_iam_role.k8s-worker-nodes-role.name
}

resource "aws_iam_role" "k8s-worker-nodes-role" {
  name = "k8s-worker-nodes-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF

  tags = {
    Name        = "${local.my_name}-k8s-worker-nodes-role"
    Deployment  = "${local.my_deployment}"
    Prefix      = "${var.prefix}"
    Environment = "${var.env}"
    Region      = "${var.region}"
    Terraform   = "true"
  }
}

# Allow to get encrypted parameters from the SSM Parameter store
resource "aws_iam_policy" "k8s-worker-nodes-policy" {
  name        = "k8s-worker-nodes-policy"
  description = "k8s-worker-nodes-policy to get SSM Parameters"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
	{
      "Effect": "Allow",
      "Action": [
	    "ssm:GetParameter",
        "ssm:GetParameters",
		"ssm:DescribeParameters"
      ],
      "Resource": [
        "*"
      ]
    },
	{
	  "Effect": "Allow",
	  "Action": [
		  "ec2:DescribeInstances",
		  "ec2:DescribeRegions",
		  "ecr:GetAuthorizationToken",
		  "ecr:BatchCheckLayerAvailability",
		  "ecr:GetDownloadUrlForLayer",
		  "ecr:GetRepositoryPolicy",
		  "ecr:DescribeRepositories",
		  "ecr:ListImages",
		  "ecr:BatchGetImage"
	  ],
	  "Resource": "*"
	} 
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "k8s-worker-nodes-policy-attach" {
  role       = aws_iam_role.k8s-worker-nodes-role.name
  policy_arn = aws_iam_policy.k8s-worker-nodes-policy.arn
}

data "aws_ami" "latest_aws_linux_2_ami" {
	most_recent = true
	owners 		= ["amazon"]

	filter {
		name   = "name"
		values = ["amzn2-ami-hvm*"]
	}

    filter {
       name   = "architecture"
       values = ["x86_64"]
    } 
}

data "template_file" "userdata" {
	template = file("../../modules/k8s-worker-nodes/user_data.sh")
	vars = {
		master_private_ip_addr = "${var.master_private_ip_addr}"
	}
}
/*
resource "aws_instance" "k8s-worker-nodes" {
  ami                    = data.aws_ami.latest_aws_linux_2_ami.id
  instance_type          = var.worker_instance_type
  vpc_security_group_ids = [var.k8s-worker-nodes-private-subnet_sg_id]
  subnet_id              = var.private_subnet_ids[0][0]
  key_name               = local.my_key_name
  iam_instance_profile   = aws_iam_instance_profile.k8s-worker-nodes-profile.name
  user_data 			 = data.template_file.userdata.rendered
	
  tags = {
    Name        = "${local.my_name}-k8s-worker-nodes"
    Deployment  = "${local.my_deployment}"
    Prefix      = var.prefix
    Environment = var.env
    Region      = var.region
    Terraform   = "true"
  }
}
*/

resource "aws_launch_configuration" "k8s-worker-nodes-launch-conf" {
  name_prefix            = "k8s-worker-nodes-launch-conf"
  image_id               = data.aws_ami.latest_aws_linux_2_ami.id
  instance_type          = var.worker_instance_type
  security_groups 		 = [ var.k8s-worker-nodes-private-subnet_sg_id]
  key_name               = local.my_key_name
  iam_instance_profile   = aws_iam_instance_profile.k8s-worker-nodes-profile.name
  user_data 			 = data.template_file.userdata.rendered
}

resource "aws_autoscaling_group" "k8s-worker-nodes-asg"{
  name                 = "k8s-worker-nodes-asg"
  launch_configuration = aws_launch_configuration.k8s-worker-nodes-launch-conf.name
  min_size             = var.asg_worker_nodes_min_size
  max_size             = var.asg_worker_nodes_max_size
  vpc_zone_identifier  = flatten(var.private_subnet_ids)

  tags = [
		{
			key = "Name"
			value = "${local.my_name}-k8s-worker-nodes"
			propagate_at_launch = true
		},
		{
			key = "Deployment"
			value = "${local.my_deployment}"
			propagate_at_launch = true
		},		
		{
			key = "Prefix"
			value = var.prefix
			propagate_at_launch = true
		},		
		{
			key = "Environment"
			value = var.env 
			propagate_at_launch = true
		},
		{
			key = "Region"
			value = var.region
			propagate_at_launch = true
		},		
		{
			key = "Terraform"
			value = "true"
			propagate_at_launch = true
		},
		{
			key = "kubernetes.io/cluster/kubernetes"
			value = "owned"
			propagate_at_launch = true
		},		
  ]
  
  lifecycle {
    create_before_destroy = true
  }
}
