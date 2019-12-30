output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

# Kubernetes nodes network configuration needs these.
output "private_subnet_ids" {
  value = ["${aws_subnet.private-subnet.*.id}"]
}

output "public_subnet_ids" {
  value = ["${aws_subnet.public-subnet.*.id}"]
}

output "internet_gateway_id" {
  value = ["${aws_internet_gateway.internet-gateway.id}"]
}

data "aws_subnet_ids" "output-private-subnet-ids" {
  vpc_id = "${aws_vpc.vpc.id}"
}

data "aws_subnet" "output-private-subnet" {
  count = "${length(var.private_subnet_count)}"    
  id    = "${tolist(data.aws_subnet_ids.output-private-subnet-ids.ids)[count.index]}"
}

output "private_subnet_cidr_blocks" {
  value = ["${data.aws_subnet.output-private-subnet.*.cidr_block}"]
}

# Kubernetes nodes needs to know the availability zone names used for Kubernetes nodes.
output "private_subnet_availability_zones" {
  value = ["${data.aws_subnet.output-private-subnet.*.availability_zone}"]
}

output "alb-public-subnet-sg_id" {
  value = "${aws_security_group.alb-public-subnet-sg.id}"
}

output "k8s_master_nodes_private_subnet_sg_id" {
  value = "${aws_security_group.k8s-master-nodes-private-subnet-sg.id}"
}

output "k8s_worker_nodes_private_subnet_sg_id" {
  value = "${aws_security_group.k8s-worker-nodes-private-subnet-sg.id}"
}

output "bastion_public_subnet_sg_id" {
  value = "${aws_security_group.bastion-public-subnet-sg.id}"
}

output "database_private_subnet_sg_id" {
  value = "${aws_security_group.database-private-subnet-sg.id}"
}

output "k8s_deployer_lambda_private_subnet_sg_id" {
  value = "${aws_security_group.k8s-deployer-lambda-private-subnet-sg.id}"
}


output "public_subnet_route_table_id" {
  value = "${aws_route_table.public-subnet-route-table.id}"
}
output "private_subnet_route_table_id" {
  value = "${aws_route_table.private-subnet-route-table.id}"
}
