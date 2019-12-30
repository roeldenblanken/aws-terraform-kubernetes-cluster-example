#! /bin/bash
sudo yum update -y
sudo yum install mysql docker git tree -y
sudo systemctl enable docker
sudo systemctl start docker