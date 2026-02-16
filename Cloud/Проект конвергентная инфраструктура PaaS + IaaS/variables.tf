variable "compute_flavor" {
  type = string
  default = "STD2-1-1"
}

variable "key_pair_name" {
  type = string
  default = "main"
}

variable "ms1" {
  type = string
  default = "MS1"
}

variable "me1" {
  type = string
  default = "ME1"
}

variable "gz1" {
  type = string
  default = "GZ1"
}

variable "lastname" {
  default = "liskov"
}

variable "db_user_password" {
  type      = string
  default = "DfKNKsafksnafkwe#@$+_fsdsfsfFDn123!"
  sensitive = true
}

variable "db-instance-flavor" {
  type    = string
  default = "STD2-2-8"
}