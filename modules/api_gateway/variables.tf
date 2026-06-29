variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "prod"
}

variable "routes" {
  description = "REST API routes"
  type = map(object({
    path_part            = string
    http_method          = string
    lambda_invoke_arn    = string
    lambda_function_name = string
    authorization       = string
  }))
}

variable "aws_region" {
  type = string
}

variable "authorizer_invoke_arn" {
  type = string
}

variable "authorizer_function_name" {
  type = string
}
