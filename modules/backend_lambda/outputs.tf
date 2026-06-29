output "function_names" {
  value = {
    for name,fn in aws_lambda_function.this : name => fn.function_name
  }
}

output "function_arns" {
  value = {
    for name,fn in aws_lambda_function.this : name => fn.arn
  }
}

output "invoke_arns" {
  value = {
    for name,fn in aws_lambda_function.this : name => fn.invoke_arn
  }
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda_exec_role.arn
}
