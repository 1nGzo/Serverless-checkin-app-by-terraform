variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "s3_bucket_id" {
  description = "Frontend S3 bucket id"
  type        = string
}

variable "s3_bucket_arn" {
  description = "Frontend S3 bucket arn"
  type        = string
}

variable "s3_bucket_regional_domain_name" {
  description = "Frontend S3 bucket regional domain name"
  type        = string
}

variable "api_gateway_domain_name" {
  description = "API Gateway domain name without protocol and stage"
  type        = string
}

variable "api_gateway_stage" {
  description = "API Gateway stage name"
  type        = string
}
