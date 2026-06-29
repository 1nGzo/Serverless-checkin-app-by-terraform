resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project_name}-lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name = "${var.project_name}-lambda-dynamodb-policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = concat(
          var.dynamodb_table_arns,
          [
            for arn in var.dynamodb_table_arns : "${arn}/index/*"
          ]
        )
      }
    ]
  })
}

resource "aws_lambda_function" "this" {
  for_each = var.lambda_functions

  function_name = each.key
  role = aws_iam_role.lambda_exec_role.arn
  handler = each.value.handler
  runtime = each.value.runtime
  filename = each.value.filename

  source_code_hash = filebase64sha256(each.value.filename)

  timeout = each.value.timeout
  memory_size = each.value.memory_size

  environment {
    variables = each.value.environment_variables
  }

  depends_on = [ 
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy.lambda_dynamodb_policy
  ]
}
