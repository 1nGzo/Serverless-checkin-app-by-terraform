variable "project_name" {
  type = string
}

variable "users_table_name" {
  type    = string
  default = "users"
}

variable "checkin_table_name" {
  type    = string
  default = "user_checkin_data"
}

variable "stats_table_name" {
  type    = string
  default = "checkinappstats"
}
