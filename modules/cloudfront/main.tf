data "aws_cloudfront_cache_policy" "s3_caching_optimized" {
  name = "Managed-CachingOptimized" # AWS 托管缓存策略，适合静态资源
}

data "aws_cloudfront_cache_policy" "api_caching_disabled" {
  name = "Managed-CachingDisabled" # API 请求不缓存，避免登录/用户数据出问题
}

data "aws_cloudfront_origin_request_policy" "api_all_viewer_except_host_header" {
  name = "Managed-AllViewerExceptHostHeader" # 转发请求信息给 API Gateway，但不转发 Host 头
}

resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "${var.project_name}-s3-oac" # CloudFront 访问 S3 的 OAC
  description                       = "OAC for ${var.project_name} frontend S3 bucket"
  origin_access_control_origin_type = "s3"    # 目标源是 S3
  signing_behavior                  = "always" # CloudFront 总是签名请求
  signing_protocol                  = "sigv4"  # 使用 AWS SigV4 签名
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true        # 启用 CloudFront
  comment             = var.project_name
  default_root_object = "index.html" # 访问根路径时返回 index.html

  origin {
    origin_id                = "s3-frontend"                         # S3 Origin 的内部标识
    domain_name              = var.s3_bucket_regional_domain_name     # S3 REST Endpoint，不是 website endpoint
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id

    s3_origin_config {
      origin_access_identity = "" # 使用 OAC 时这里留空，但 block 仍然需要
    }
  }

  origin {
    origin_id   = "api-gateway"                # API Gateway Origin 的内部标识
    domain_name = var.api_gateway_domain_name  # 例如 xxxxx.execute-api.ap-northeast-1.amazonaws.com
    origin_path = "/${var.api_gateway_stage}"  # 例如 /prod，CloudFront 转发时自动补上 stage

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only" # CloudFront 到 API Gateway 只走 HTTPS
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "s3-frontend" # 默认请求走 S3
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"] # 静态资源只需要这些方法
    cached_methods  = ["GET", "HEAD"]            # 只有 GET/HEAD 会被缓存

    cache_policy_id = data.aws_cloudfront_cache_policy.s3_caching_optimized.id
    compress        = true # 自动压缩静态资源
  }

  ordered_cache_behavior {
    path_pattern           = "/api/*"      # 匹配前端请求 /api/login 这类路径
    target_origin_id       = "api-gateway" # 命中 /api/* 后转发给 API Gateway
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS",
      "PUT",
      "POST",
      "PATCH",
      "DELETE"
    ]

    cached_methods = ["GET", "HEAD"] # 虽然允许 GET，但缓存策略会禁用缓存

    cache_policy_id          = data.aws_cloudfront_cache_policy.api_caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.api_all_viewer_except_host_header.id

    compress = true
  }

  custom_error_response {
    error_code         = 403          # S3 REST Endpoint 找不到对象时常见是 403
    response_code      = 200          # 给前端返回 200
    response_page_path = "/index.html" # SPA 刷新页面时回退到 index.html
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none" # 不做地区限制
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true # 第一阶段先用 CloudFront 默认域名证书
  }

  depends_on = [
    aws_cloudfront_origin_access_control.s3_oac
  ]
}

resource "aws_s3_bucket_policy" "allow_cloudfront_oac" {
  bucket = var.s3_bucket_id # 给前端 S3 bucket 加访问策略

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"

        Principal = {
          Service = "cloudfront.amazonaws.com" # 允许 CloudFront 服务访问
        }

        Action = [
          "s3:GetObject"
        ]

        Resource = "${var.s3_bucket_arn}/*" # 只允许读取 bucket 内对象

        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.this.arn # 限定只有这个 Distribution 能访问
          }
        }
      }
    ]
  })
}
