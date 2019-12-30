#! /bin/bash
# Redirect all output with -> exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
sudo yum update -y
sudo yum install mysql docker git tree jq -y
sudo systemctl enable docker
sudo systemctl start docker

# Placing the certificate to login to the servers in the private subnet
aws ssm get-parameter --name Work.pem --region eu-west-1 --with-decryption | jq -r .Parameter.Value | tee /root/Work.pem /home/ec2-user/Work.pem >/dev/null
chmod 600 /root/Work.pem /home/ec2-user/Work.pem

# Adding env var to path
sudo echo 'PATH=$PATH:/usr/local/bin'  | tee -a /root/.bashrc /home/ec2-user/.bashrc
sudo echo 'export PATH=$PATH'  | tee -a /root/.bashrc /home/ec2-user/.bashrc 
source ~/.bashrc

# Lambda k8s deployer script
# Used for provisioning the deployer Lambda python script (ref: https://aws.amazon.com/fr/blogs/compute/scheduling-ssh-jobs-using-aws-lambda/)
export deployer_lambda_dir=/var/tmp/deployer_lambda
sudo mkdir -p $deployer_lambda_dir
sudo cat > $deployer_lambda_dir/script.py <<EOF
import io
import sys
import boto3
import paramiko

def worker_handler(event=None, context=None):
    host="ec2-user@{}".format("${master_private_ip_addr}")
    bastion_host = "bastion_public_ip_to_be_changed_in_user_data_bastion_script"
	
    # Get the private certificate from the SSM parameter store
    session = boto3.Session(region_name='eu-west-1')
    ssm = session.client('ssm')
    response = ssm.get_parameter(
     	Name='Work.pem',
    	WithDecryption=True
    )
	
    private_key = response['Parameter']['Value']	
    k = paramiko.RSAKey.from_private_key(io.StringIO(private_key))
    c = paramiko.SSHClient()
    c.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    print("Connecting to " + bastion_host)
    c.connect(hostname=bastion_host, username="ec2-user", pkey=k)
    print("Connected to " + bastion_host)

    env = event['ENV']
    app_name = event['APP_NAME']
    code_pipeline = event['CODEPIPELINE']
    git_repository_url = event['GIT_REPOSITORY_URL']
    git_branch = event['GIT_BRANCH']
    git_commit_hash = event['GIT_COMMIT_HASH']
	
    work_dir = "/var/tmp/" + code_pipeline
	
    commands = [
        "sudo ssh -o StrictHostKeyChecking=no -i Work.pem {}".format(host) + " \"" + " sudo rm -rf " + work_dir + ";mkdir -p " + work_dir + ";sudo chown -R ec2-user:ec2-user " + work_dir +";\"" ,
        "sudo ssh -o StrictHostKeyChecking=no -i Work.pem {}".format(host) + " \"" + " git clone -b " + git_branch + " " +  git_repository_url + " " + work_dir + ";\"",
        "sudo ssh -o StrictHostKeyChecking=no -i Work.pem {}".format(host) + " \"" + " git -C " + work_dir + " checkout "+ git_commit_hash + ";\"",
        "sudo ssh -o StrictHostKeyChecking=no -i Work.pem {}".format(host) + " \"" + " cd " + work_dir + "; helm lint " + app_name + " ./kubernetes/application -f ./kubernetes/application/" + env + "_values.yaml;\"",
        "sudo ssh -o StrictHostKeyChecking=no -i Work.pem {}".format(host) + " \"" + " cd " + work_dir + "; helm template " + app_name + " ./kubernetes/application -f ./kubernetes/application/" + env + "_values.yaml --output-dir ./kubernetes/outputdir;\"",
        "sudo ssh -o StrictHostKeyChecking=no -i Work.pem {}".format(host) + " \"" + " cd " + work_dir + "; sudo kubectl apply -f ./kubernetes/outputdir/application/templates;\"",		
    ]
	
    for command in commands:
        print("Executing {}".format(command))
        stdin, stdout, stderr = c.exec_command(command)
        print(stdout.read())
        print(stderr.read())

    return {
        'message': "Script execution completed. See Cloudwatch logs for complete output"
    }

# Used for local testing	
if __name__ == '__main__':
    worker_handler(sys.argv[0])
	
#  python3 -c 'import script; print(script.worker_handler({"ENV": "dev", "APP_NAME": "hello-world", "CODEPIPELINE": "codepipeline", "GIT_REPOSITORY_URL":"https://github.com/roeldenblanken/docker-hello-world", "GIT_BRANCH": "master", "GIT_COMMIT_HASH": "267e20ac153bb2f36e1865d7d0879492d37d37dd"}))'
EOF

# replace the bastion public ip addr so that the lambda function can reach it
export bastion_host_public_ip_addr=`curl http://169.254.169.254/latest/meta-data/public-ipv4`
sudo sed -i "s/bastion_public_ip_to_be_changed_in_user_data_bastion_script/$bastion_host_public_ip_addr/g" $deployer_lambda_dir/script.py
# Install dependancies
sudo yum install gcc ${k8s_deployer_lambda_python_run_time} python-pip -y
sudo python3 --version # Select the right runtime environment in Lambda
sudo pip3 install paramiko -t $deployer_lambda_dir
sudo pip3 install boto3 -t $deployer_lambda_dir
# Dont use sudo for below command. Otherwise the 'cd' will not work
cd $deployer_lambda_dir; zip -r script.zip .
# Upload the artifacts to Lambda
aws lambda update-function-code --function-name ${k8s_deployer_lambda_name} --zip-file fileb://$deployer_lambda_dir/script.zip --region eu-west-1

# Test the Lambda function
# aws lambda invoke --function-name k8s_deployer_lambda --payload '{"ENV": "dev", "APP_NAME": "hello-world", "CODEPIPELINE": "codepipeline", "GIT_REPOSITORY_URL":"https://github.com/roeldenblanken/docker-hello-world", "GIT_BRANCH": "master", "GIT_COMMIT_HASH": "267e20ac153bb2f36e1865d7d0879492d37d37dd"}'  --region eu-west-1 response.json
