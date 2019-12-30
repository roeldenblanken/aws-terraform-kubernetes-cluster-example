output "k8s_deployer_lambda_name" {
  value       = aws_lambda_function.k8s_deployer_lambda.function_name
  description = "The Lambda function name."
}
output "k8s_deployer_lambda_arn" {
  value       = aws_lambda_function.k8s_deployer_lambda.arn
  description = "The Lambda function arn."
}