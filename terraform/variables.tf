variable "region" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}
variable "admin_user_arn" {
  type = string
}

variable "github_role_arn" {
  type = string
}
