output "s3_bucket_name" {
  value = module.frontend_s3.bucket_id
}

output "api_gateway_invoke_url" {
  value = module.api_gateway.invoke_url
}

output "cloudfront_distribution_id" {
  value = module.cloudfront.distribution_id
}

output "cloudfront_domain_name" {
  value = module.cloudfront.domain_name
}

output "site_url" {
  value = "https://${module.cloudfront.domain_name}"
}
