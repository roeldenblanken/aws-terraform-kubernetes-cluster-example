locals {
  my_name       = "${var.prefix}-${var.env}-k8s-master-nodes"
  my_deployment = "${var.prefix}-${var.env}"
  my_key_name   = "Work"
}

resource "aws_iam_instance_profile" "k8s-master-nodes-profile" {
  name = "k8s-master-nodes-profile"
  role = aws_iam_role.k8s-master-nodes-role.name
}

resource "aws_iam_role" "k8s-master-nodes-role" {
  name = "k8s-master-nodes-role"
  
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
    Name        = "${local.my_name}-k8s-master-nodes-role"
    Deployment  = "${local.my_deployment}"
    Prefix      = "${var.prefix}"
    Environment = "${var.env}"
    Region      = "${var.region}"
    Terraform   = "true"
  }
}

# Allow to get encrypted parameters from the SSM Parameter store
resource "aws_iam_policy" "k8s-master-nodes-policy" {
  name        = "k8s-master-nodes-policy"
  description = "k8s-master-nodes-policy to get SSM Parameters"

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
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "ec2:DescribeInstances",
        "ec2:DescribeRegions",
        "ec2:DescribeRouteTables",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeVolumes",
        "ec2:CreateSecurityGroup",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:ModifyInstanceAttribute",
        "ec2:ModifyVolume",
        "ec2:AttachVolume",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CreateRoute",
        "ec2:DeleteRoute",
        "ec2:DeleteSecurityGroup",
        "ec2:DeleteVolume",
        "ec2:DetachVolume",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:DescribeVpcs",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:AttachLoadBalancerToSubnets",
        "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:CreateLoadBalancerPolicy",
        "elasticloadbalancing:CreateLoadBalancerListeners",
        "elasticloadbalancing:ConfigureHealthCheck",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:DeleteLoadBalancerListeners",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeLoadBalancerAttributes",
        "elasticloadbalancing:DetachLoadBalancerFromSubnets",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:DescribeLoadBalancerPolicies",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetHealth",
        "elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:ModifyTargetGroup",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",
        "iam:CreateServiceLinkedRole",
        "kms:DescribeKey"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "k8s-master-nodes-policy-attach" {
  role       = aws_iam_role.k8s-master-nodes-role.name
  policy_arn = aws_iam_policy.k8s-master-nodes-policy.arn
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

resource "aws_instance" "k8s-master-nodes" {
  ami                    = data.aws_ami.latest_aws_linux_2_ami.id
  instance_type          = var.master_instance_type
  vpc_security_group_ids = ["${var.k8s-master-nodes-private-subnet_sg_id}"]
  subnet_id              = var.private_subnet_ids[0][0]
  key_name               = local.my_key_name
  iam_instance_profile   = aws_iam_instance_profile.k8s-master-nodes-profile.name
  user_data = file("../../modules/k8s-master-nodes/user_data.sh")
	
  tags = {
    Name        = "${local.my_name}-k8s-master-nodes"
    Deployment  = "${local.my_deployment}"
    Prefix      = var.prefix
    Environment = var.env
    Region      = var.region
    Terraform   = "true"
	"kubernetes.io/cluster/kubernetes" = "owned"
  }
}