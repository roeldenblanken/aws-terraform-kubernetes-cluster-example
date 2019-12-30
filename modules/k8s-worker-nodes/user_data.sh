#! /bin/bash
# Redirect all output with -> exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
sudo yum update -y
sudo yum install git curl tree socat jq -y

# Set the correct hostname (needed for aws kubernetes provider - Ubuntu servers)
hostnamectl set-hostname `curl http://169.254.169.254/latest/meta-data/local-hostname`

# Adding env var to path to make kubectl command work"
sudo echo 'PATH=$PATH:/usr/local/bin'  | tee -a /root/.bashrc /home/ec2-user/.bashrc
sudo echo 'export PATH=$PATH'  | tee -a /root/.bashrc /home/ec2-user/.bashrc 

# Enabling shell autocompletion.
sudo yum install bash-completion -y
sudo echo 'source <(kubectl completion bash)' | tee -a /root/.bashrc /home/ec2-user/.bashrc
sudo chown ec2-user:ec2-user /usr/share/bash-completion/bash_completion

# Load profile
sudo source ~/.bashrc

# Install kubectl, docker
sudo echo [kubernetes] > /etc/yum.repos.d/kubernetes.repo
sudo echo name=Kubernetes >> /etc/yum.repos.d/kubernetes.repo
sudo echo baseurl=https\://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64 >> /etc/yum.repos.d/kubernetes.repo
sudo echo enabled=1 >> /etc/yum.repos.d/kubernetes.repo
sudo echo gpgcheck=1 >> /etc/yum.repos.d/kubernetes.repo
sudo echo repo_gpgcheck=0 >> /etc/yum.repos.d/kubernetes.repo
sudo echo gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg >> /etc/yum.repos.d/kubernetes.repo

sudo yum install kubelet kubectl docker -y
sudo systemctl restart docker && systemctl enable docker
sudo systemctl restart kubelet && systemctl enable kubelet.service

# Kubernetes TLS bootstrapping
# Place the certificate on the worker and master node: /etc/kubernetes/pki/ca.crt
sudo mkdir -p /etc/kubernetes/pki
aws ssm get-parameter --name KUBERNETES_CA_CERT --region eu-west-1 --with-decryption | jq -r .Parameter.Value > /etc/kubernetes/pki/ca.crt

# Create the bootstrap_config on the worker node
# But first get the bootstrap token from ssm
export token=`aws ssm get-parameter --name KUBERNETES_BOOTSTRAP_TOKEN --region eu-west-1 --with-decryption | jq -r .Parameter.Value`
sudo kubectl config --kubeconfig=/var/lib/kubelet/bootstrap-kubeconfig set-cluster kubernetes --server='https://${master_private_ip_addr}:6443' --certificate-authority=/etc/kubernetes/pki/ca.crt --embed-certs=true
sudo kubectl config --kubeconfig=/var/lib/kubelet/bootstrap-kubeconfig set-credentials kubelet-bootstrap --token=$token
sudo kubectl config --kubeconfig=/var/lib/kubelet/bootstrap-kubeconfig set-context kubernetes --user=kubelet-bootstrap --cluster=kubernetes
sudo kubectl config --kubeconfig=/var/lib/kubelet/bootstrap-kubeconfig use-context kubernetes

# Add the bootstrap config to the systemctl unit file on the worker
sudo sed -i "s/.*ExecStart=\/usr\/bin\/kubelet.*/ExecStart=\/usr\/bin\/kubelet --bootstrap-kubeconfig=\/var\/lib\/kubelet\/bootstrap-kubeconfig --kubeconfig=\/var\/lib\/kubelet\/kubeconfig --cloud-provider=aws/g" /usr/lib/systemd/system/kubelet.service
sudo systemctl daemon-reload
sudo systemctl restart kubelet
sleep 5
sudo journalctl --unit=kubelet.service -n 100 --no-pager