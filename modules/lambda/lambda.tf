locals {
  my_name       = "${var.prefix}-${var.env}-k8s-deployer-lambda"
  my_deployment = "${var.prefix}-${var.env}"
  my_key_name   = "Work"
}

resource "aws_iam_role" "iam_for_k8s_deployer_lambda" {
  name = "${local.my_name}-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name        = "${local.my_name}-role"
    Deployment  = "${local.my_deployment}"
    Prefix      = "${var.prefix}"
    Environment = "${var.env}"
    Region      = "${var.region}"
    Terraform   = "true"
  }
}

# Allow the k8s deployer Lambda to store logs in AWS CloudWatch
resource "aws_iam_policy" "k8s-deployer-lambda-policy" {
  name        = "${local.my_name}-policy"
  description = "k8s-deployer lambda-policy to get SSM Parameters"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    },
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
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "k8s-deployer-lambda-policy-attach" {
  role       = aws_iam_role.iam_for_k8s_deployer_lambda.name
  policy_arn = aws_iam_policy.k8s-deployer-lambda-policy.arn
}

resource "aws_lambda_function" "k8s_deployer_lambda" {
  filename      = data.archive_file.k8s_deployer_lambda_zip_inline.output_path
  function_name = "k8s_deployer_lambda"
  role          = aws_iam_role.iam_for_k8s_deployer_lambda.arn
  handler       = "script.worker_handler"
  timeout       = 10
  
  source_code_hash = data.archive_file.k8s_deployer_lambda_zip_inline.output_base64sha256

  runtime = var.k8s_deployer_lambda_python_run_time

  environment {
    variables = {
      foo = "bar"
    }
  }
  
  lifecycle {
    ignore_changes = [
      # Ignore changes to source_code_hash, e.g. because this will be overwritten by the Bastion host's user data script
      source_code_hash,
    ]
  }
}

# Allow CodeBuild to invoke the k8s-deployer Lambda function.
resource "aws_lambda_permission" "k8s_deployer_lambda_permission" {
  statement_id  = "AllowCodeBuildInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.k8s_deployer_lambda.function_name
  principal     = "codebuild.amazonaws.com"

  source_arn 	= aws_lambda_function.k8s_deployer_lambda.arn
}

data "archive_file" "k8s_deployer_lambda_zip_inline" {
  type        = "zip"
  output_path = "../../modules/k8s_deployer_lambda_zip_inline.zip"
  source {
    content  = <<EOF
print("dummy code. The lambda provisioning happens in the Bastion host's userdata due to an dependancy package needed")
EOF
    filename = "script.py"
  }
}
