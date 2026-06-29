resource "aws_dynamodb_table" "users" {
  name = var.users_table_name
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "email"

  attribute {
    name = "email"
    type = "S"
  }
}

resource "aws_dynamodb_table" "user_checkin_data" {
  name = var.checkin_table_name
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "email"

  attribute {
    name = "email"
    type = "S"
  }

}

resource "aws_dynamodb_table" "checkinappstats" {
  name = var.stats_table_name
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "StatID"

  attribute {
    name = "StatID"
    type = "S"
  }

}
