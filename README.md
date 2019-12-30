# Architecture
The AWS solution is depicted in the diagram below. 
![Image description](architecture-diagram.png)

#### Summary
Terraform will create a Kubernetes cluster using Kubeadm and with an AWS cloudprovider plugin.

#### Important info
- The Kubernetes worker nodes are in an autoscaling group. 
- Each node will join the cluster based on a bootstrap token.
- The AWS cloudprovider plugin will automatically create a loadbalancer for each Kubernetes service with type LoadBalancer.
- The Lambda deployer is used to deploy Kubernetes resources.

# Deployment Instructions
Install Terraform. Clone this project. 

1. Open console in [dev](envs/dev) folder. 
2. Configure the terraform backend (S3 Bucket and DynamoDB table as instructed in the env.tf file). 
3. Then usual export AWS_ACCESS_KEY_ID=, AWS_SECRET_ACCESS_KEY=, AWS_DEFAULT_REGION=eu-west-1 and terraform init, get, plan and apply commands.
4. The infrastructure will be provisioned

# CI/CD
**Important** wait untill the user data in each ec2 instance has completely finished untill starting an app deployment

After the infrastructure has been set up you can continue with either manually or automatically deploying a Kubernetes application:

### Manual deployment
```bash
aws lambda invoke --function-name k8s_deployer_lambda --payload '{"ENV": "dev", "APP_NAME": "hello-world", "CODEPIPELINE": "codepipeline", "GIT_REPOSITORY_URL":"https://github.com/roeldenblanken/docker-hello-world", "GIT_BRANCH": "master", "GIT_COMMIT_HASH": "267e20ac153bb2f36e1865d7d0879492d37d37dd"}'  --region eu-west-1 response.json
```

### Automatic deployment
The CI/CD pipline (codePipeline) is created in https://github.com/roeldenblanken/aws-terraform-code-pipeline-ci-cd-example

Make use of the "k8s-app" example pipeline.

### The intended internal Kubernetes application architecture depicted below

![Image description](architecture-with-ingress.jpg)

# Requirements
Requires the following secure string parameters to be present in the AWS SSM Parameter store

| Parameter | Description |
| ------------- | ------------- |
| KUBERNETES_BOOTSTRAP_TOKEN_ID  | The id part of the kubernetes bootstrap token. See https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet-tls-bootstrapping/  |
| KUBERNETES_BOOTSTRAP_TOKEN_SECRET  | The secret part of the kubernetes bootstrap token. See https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet-tls-bootstrapping/  |
| KUBERNETES_BOOTSTRAP_TOKEN  | The complete kubernetes bootstrap token. See https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet-tls-bootstrapping/  |
| KUBERNETES_CA_CERT  | The root certificate authority that can be used by the cluster  |
| KUBERNETES_CA_KEY  | The root key certificate authority that can be used by the cluster  |
| DB_PASSWORD  | The password that needs to be used when provisioning the RDS database.   |
| work.pem  | The private key that is placed on each host to login with via the Bastion host |

Example KUBERNETES_CA_CERT
```
-----BEGIN CERTIFICATE-----
MIICyDCCAbCgAwIBAgIBADANBgkqhkiG9w0BAQsFADAVMRMwEQYDVQQDEwprdWJl
cm5ldGVzMB4XDTE5MTIyNzIyMDIzN1oXDTI5MTIyNDIyMDIzN1owFTETMBEGA1UE
AxMKa3ViZXJuZXRlczCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAPZa
FmmNUi4OvwlFdvbANQKW0ayAZBjrKS1QAU/7MP97l2ZVQdWV5TTKcCxciHtJHhTw
GiJeOYllWhfpdxpaGgHHgZkXhaS2O6e21Qz66a15gZxPlLkxHlJCM/e/GU/txNZ3
fe/qQa2QlCyA7/dUQXwsgTWF5eig/Ul90z/waJ/PRhoXFyddlVt2QE8B3KGdscMa
1F0a1JMdB9+PqsqHHswTVd4e8WzUs/FyeJnt3Ock9kC1EZlWhgnK3lE/IAIEjB8X
57dCl/mb7Xiqk+dmteEy9lfI/jWsIVIY2Tl2t+igO5TSEfOm0QrhKtsEByhkScdE
q1TdtFxwgmTXNoQM0CsCAwEAAaMjMCEwDgYDVR0PAQH/BAQDAgKkMA8GA1UdEwEB
/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBAOkk71dMKSu9NZ9KUg9nqF6efiiS
W/Omg6wZcd8y+Xl139vym1JDiVq4w7VM/4aALtgoGAXYbH133hQ4uOrhhPJeixsn
5ysFPJJn4TPizyZnL5HyoWJ6XofrvxVRbZFG6j14v1kOaijxYizyANFVgHDCmNyE
XBdCgVPpnbgXClB3lABSquu07iBDsce7+NZfbo07tsPmO8KXKmk0pbl+/IXgSsDb
dplt+ItjIG/nBe1p0uV21mqDo/jumEYH6wJaebOYSnriev36YbyyZ6nDU4MirFex
1WKaEtAZYAejwnktuCsG/N7BEmqpdK0TjoMYHCT1g2/s0zMJaMf+xB71Pis=
-----END CERTIFICATE-----
```

Example KUBERNETES_CA_KEY
```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA9loWaY1SLg6/CUV29sA1ApbRrIBkGOspLVABT/sw/3uXZlVB
1ZXlNMpwLFyIe0keFPAaIl45iWVaF+l3GloaAceBmReFpLY7p7bVDPrprXmBnE+U
uTEeUkIz978ZT+3E1nd97+pBrZCULIDv91RBfCyBNYXl6KD9SX3TP/Bon89GGhcX
J12VW3ZATwHcoZ2xwxrUXRrUkx0H34+qyocezBNV3h7xbNSz8XJ4me3c5yT2QLUR
mVaGCcreUT8gAgSMHxfnt0KX+ZvteKqT52a14TL2V8j+NawhUhjZOXa36KA7lNIR
86bRCuEq2wQHKGRJx0SrVN20XHCCZNc2hAzQKwIDAQABAoIBAAfbM5/GG/rQCZOY
HYUc+BPPD3y603Zf+X4ycPhGAHgFTvy6d1ECaL7YPd+MS+XynPz58ztpWdhh3Q+q
KFw0x2OLIzzonSB1l01v7TduwQkBOPrtJscJI/hnmBSsiXgdEwvr355JEDMiyzbo
Hb77duMo4C3+ySg0Ch/P3W7KkeuWtpcBX7Q8fr/ZWKvEu04VPSgjqUh3iUmkOolh
JvLO419D+H+9QdfPekumAWZ+Xz8l7Kskzip/vxErV5fCDLAcH5pJZ2firP0YNVH8
ggDZN+f18UGOn0xL4EzYZJUIEYb1PZoUXZEY97jbPouiMzBh6TlKI6rMDPqUxQNK
umOcgjECgYEA+TNO/jdmdl1DwEh5W3sr0x5rImjioem1hbx4ckcZdLICmQ5JTEac
KjTYr233HbRy0Iw6ObQYe3xQ4UcDt8koICi92guPnOcPKZhZfQyBTl3xalSRptbU
STkkDxAZUjR+Dk41lg59D/DAD5rb3WocObLkwpLxX9KiMBlW5VVHwIUCgYEA/RLh
u6Yz/9a+kA6wy0c0eUyjwxYru/L01nTzagDgSorVuicTbiTVjgIjFsScoKKBqhsw
dIU48yryLafLpLYwe9XkQfAJmGAPiBQHG5ako2Mux5phng5Y35p2sngq3SBRojZy
ZDLBS0pFb6jqVA2E3Xeq/+pg9164kX3AyO82BO8CgYEAoGEXG6EH/nFzoxKBmBCj
WdIf3RtnkBDbVGDBm7qKdYIDDgIVxlNDOh6cvfqlqaZypik5Z92yS/bsDrAngmah
vmC6HtSF7tL9/SUhossjhQ4MywP2YUutgBqYTGFuCmviHM7Uyeg1MMcetGxTyCH8
XF33wAnV8nebDh2gwSOrdAkCgYBEkcIh0tWSA0Bcze4vFdrs5swURsSQxzJ5jPSL
CzO6XsWsC3xjQo2uTXvuZlU93OofCgDmAVa95Cv8HNO7jDW0x+5xwzUGWTi8GRkX
64guUOhS4syCQ8bmxvZUQuTyRxh3SCNUbMAcw0HvECh1n7gZPZxSfNHLFJoTqav7
hXzwdwKBgQCgQpEJwrS7uZPcbqBBTTLa2IjUAb/aFpArKGzSXa0LVe0BmKwdqjFY
Owq6c39x+avVLWmYrhMdw5WxKg6KHKyECrh5k7Nen1RZeWl1ZgVtGIR+u+0qKKUj
VI/esaEi4tRZKVIin7QJy7bMTygIKblGPTyAb4dw/uhrKTLX59l8Cw==
-----END RSA PRIVATE KEY-----
```
