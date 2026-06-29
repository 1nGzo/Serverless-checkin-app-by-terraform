variable "project_name" {
  description = "Project name prefix"
  type = string
}

variable "dynamodb_table_arns" {
  description = "DynamoDB table ARNs used by Lambda functions"
  type = list(string)
}

variable "lambda_functions" {
  description = "Lambda function definitions"
  type = map(object({
    filename = string
    handler = string
    runtime = string
    timeout = number
    memory_size = number
    environment_variables = optional(map(string),{})
  }))
}
