variable "project_name" {
  type    = string
}

variable "region" {
  type    = string
}

variable "vpc_cidr" {
  type    = string
}

variable "public_subnet_1a_cidr" {
  type    = string
}

variable "public_subnet_1b_cidr" {
  type    = string
}

variable "private_subnet_db_cidr" {
  type    = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "web_image" {
  type = string
}
