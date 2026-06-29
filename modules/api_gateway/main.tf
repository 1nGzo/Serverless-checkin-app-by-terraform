resource "aws_api_gateway_rest_api" "this" {
  name = "${var.project_name}-api" # REST API 的名字，例如 checkin-app-api

  endpoint_configuration {
    types = ["REGIONAL"] # 区域型 API，后面由 CloudFront 作为统一入口
  }
}

resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.this.id              # 绑定到上面创建的 REST API
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id # 挂在根路径 / 下面
  path_part   = "api"                                         # 创建 /api 这一层路径
}

resource "aws_api_gateway_resource" "routes" {
  for_each = var.routes

  rest_api_id = aws_api_gateway_rest_api.this.id # 绑定到同一个 REST API
  parent_id   = aws_api_gateway_resource.api.id  # 挂在 /api 下面
  path_part   = each.value.path_part             # 创建 /api/login、/api/register 等子路径
}

resource "aws_api_gateway_method" "routes" {
  for_each = var.routes

  rest_api_id   = aws_api_gateway_rest_api.this.id              # 当前 REST API
  resource_id   = aws_api_gateway_resource.routes[each.key].id  # 当前路径资源，例如 /api/login
  http_method   = each.value.http_method                        # 客户端请求方法，例如 GET / POST
  authorization = each.value.authorization
  authorizer_id = each.value.authorization == "CUSTOM" ? aws_api_gateway_authorizer.jwt_authorizer.id : null                                       
}

resource "aws_api_gateway_integration" "routes" {
  for_each = var.routes

  rest_api_id = aws_api_gateway_rest_api.this.id             # 当前 REST API
  resource_id = aws_api_gateway_resource.routes[each.key].id # 当前路径资源
  http_method = aws_api_gateway_method.routes[each.key].http_method

  type                    = "AWS_PROXY"                  # Lambda Proxy 集成，请求整体交给 Lambda
  integration_http_method = "POST"                       # API Gateway 调 Lambda 固定用 POST，不等于前端请求方法
  uri                     = each.value.lambda_invoke_arn # Lambda 的 invoke_arn，不是普通 function arn
}

resource "aws_lambda_permission" "allow_api_gateway" {
  for_each = var.routes

  statement_id  = "AllowExecutionFromAPIGateway-${each.key}" # 每条路由一条 Lambda 调用授权
  action        = "lambda:InvokeFunction"                    # 允许调用 Lambda
  function_name = each.value.lambda_function_name             # 被授权调用的 Lambda 函数名
  principal     = "apigateway.amazonaws.com"                  # 授权给 API Gateway 服务

  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*/${each.value.http_method}/api/${each.value.path_part}"
  # 限定只有这个 REST API 的对应方法和路径可以调用该 Lambda
  # 例：.../*/POST/api/login
}

resource "aws_lambda_permission" "allow_api_gateway_authorizer" {
  statement_id  = "AllowExecutionFromAPIGatewayAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = var.authorizer_function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/authorizers/${aws_api_gateway_authorizer.jwt_authorizer.id}"
}   #允许 API Gateway 调用 authorizer Lambda

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id # 部署当前 REST API

  triggers = {
    redeployment = sha1(jsonencode({
      api_resource = aws_api_gateway_resource.api.id        # /api 资源变化时触发重新部署
      routes       = aws_api_gateway_resource.routes        # 路由变化时触发重新部署
      methods      = aws_api_gateway_method.routes          # 方法变化时触发重新部署
      integrations = aws_api_gateway_integration.routes     # Lambda 集成变化时触发重新部署
    }))
  }

  depends_on = [
    aws_api_gateway_integration.routes # 确保所有 Lambda 集成创建完，再部署 API
  ]

  lifecycle {
    create_before_destroy = true # 新 deployment 创建成功后再销毁旧的，避免短暂不可用
  }
}

resource "aws_api_gateway_stage" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id    # 当前 REST API
  deployment_id = aws_api_gateway_deployment.this.id  # 绑定刚才创建的 deployment
  stage_name    = var.stage_name                      # 阶段名，例如 prod
}

resource "aws_api_gateway_authorizer" "jwt_authorizer" {
  name                   = "${var.project_name}-jwt-authorizer"
  rest_api_id            = aws_api_gateway_rest_api.this.id
  type                   = "TOKEN"
  authorizer_uri         = var.authorizer_invoke_arn
  identity_source        = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = 0 #先方便 debug，后面稳定了可以改成 300
}

