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
