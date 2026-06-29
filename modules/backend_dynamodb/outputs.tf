output "table_names" {
  value = {
    users = aws_dynamodb_table.users.name
    user_checkin_data = aws_dynamodb_table.user_checkin_data.name
    checkinappstats = aws_dynamodb_table.checkinappstats.name
  }
}

output "table_arns" {
  value = [
    aws_dynamodb_table.users.arn,
    aws_dynamodb_table.user_checkin_data.arn,
    aws_dynamodb_table.checkinappstats.arn
  ]
}
