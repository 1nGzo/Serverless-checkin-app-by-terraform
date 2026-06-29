module "frontend_s3" {
  source = "./modules/frontend_s3"

  project_name = var.project_name
}

module "backend_dynamodb" {
  source = "./modules/backend_dynamodb"

  project_name = var.project_name
}

module "backend_lambda" {
  source = "./modules/backend_lambda"

  project_name        = var.project_name
  dynamodb_table_arns = module.backend_dynamodb.table_arns # 把 DynamoDB 三张表 ARN 传给 Lambda IAM Policy

  lambda_functions = {
    userRegistrationFunction = {
      filename    = "${path.root}/lambda_zips/userRegistrationFunction.zip" # 直接使用现有 zip
      handler     = "index.handler"
      runtime     = "nodejs20.x"
      timeout     = 10
      memory_size = 128
    }

    loginFunction = {
      filename    = "${path.root}/lambda_zips/loginFunction.zip"
      handler     = "index.handler"
      runtime     = "nodejs20.x"
      timeout     = 10
      memory_size = 128

      environment_variables = {
        JWT_SECRET = "temporary-dev-secret-change-later"
      }
    }

    userDataFunction = {
      filename    = "${path.root}/lambda_zips/userDataFunction.zip"
      handler     = "index.handler"
      runtime     = "nodejs20.x"
      timeout     = 10
      memory_size = 128

      environment_variables = {
        USER_DATA_TABLE = "user_checkin_data"
      }
    }

    updateUserDataFunction = {
      filename    = "${path.root}/lambda_zips/updateUserDataFunction.zip"
      handler     = "index.handler"
      runtime     = "nodejs20.x"
      timeout     = 10
      memory_size = 128

      environment_variables = {
        USER_DATA_TABLE = "user_checkin_data"
      }
    }

    authorizerFunction = {
      filename    = "${path.root}/lambda_zips/authorizerFunction.zip"
      handler     = "index.handler"
      runtime     = "nodejs20.x"
      timeout     = 10
      memory_size = 128

      environment_variables = {
        JWT_SECRET = "temporary-dev-secret-change-later"
      }

    }

    checkinAppVisitCounter = {
      filename    = "${path.root}/lambda_zips/checkinAppVisitCounter.zip"
      handler     = "index.handler"
      runtime     = "nodejs20.x"
      timeout     = 10
      memory_size = 128

      environment_variables = {
        DYNAMODB_TABLE_NAME = "checkinappstats"
      }
    }
  }
}

module "api_gateway" {
  source = "./modules/api_gateway"

  project_name             = var.project_name
  aws_region               = var.aws_region
  stage_name               = var.api_stage_name
  authorizer_invoke_arn    = module.backend_lambda.invoke_arns["authorizerFunction"]
  authorizer_function_name = module.backend_lambda.function_names["authorizerFunction"]

  routes = {
    register = {
      path_part            = "register" # 最终路径：/api/register
      http_method          = "POST"
      lambda_invoke_arn    = module.backend_lambda.invoke_arns["userRegistrationFunction"]
      lambda_function_name = module.backend_lambda.function_names["userRegistrationFunction"]
      authorization        = "NONE"
    }

    login = {
      path_part            = "login" # 最终路径：/api/login
      http_method          = "POST"
      lambda_invoke_arn    = module.backend_lambda.invoke_arns["loginFunction"]
      lambda_function_name = module.backend_lambda.function_names["loginFunction"]
      authorization        = "NONE"
    }

    user_data = {
      path_part            = "user-data" # 最终路径：/api/user-data
      http_method          = "GET"
      lambda_invoke_arn    = module.backend_lambda.invoke_arns["userDataFunction"]
      lambda_function_name = module.backend_lambda.function_names["userDataFunction"]
      authorization        = "CUSTOM"
    }

    update_user = {
      path_part            = "update-user" # 最终路径：/api/update-user
      http_method          = "POST"
      lambda_invoke_arn    = module.backend_lambda.invoke_arns["updateUserDataFunction"]
      lambda_function_name = module.backend_lambda.function_names["updateUserDataFunction"]
      authorization        = "CUSTOM"
    }

    visit_counter = {
      path_part            = "visit-counter" # 最终路径：/api/visit-counter
      http_method          = "POST"
      lambda_invoke_arn    = module.backend_lambda.invoke_arns["checkinAppVisitCounter"]
      lambda_function_name = module.backend_lambda.function_names["checkinAppVisitCounter"]
      authorization        = "NONE"
    }
  }
}

module "cloudfront" {
  source = "./modules/cloudfront"

  project_name = var.project_name

  s3_bucket_id                   = module.frontend_s3.bucket_id
  s3_bucket_arn                  = module.frontend_s3.bucket_arn
  s3_bucket_regional_domain_name = module.frontend_s3.bucket_regional_domain_name

  api_gateway_domain_name = module.api_gateway.domain_name # 只传 execute-api 域名，不带 https 和 stage
  api_gateway_stage       = module.api_gateway.stage_name
}
