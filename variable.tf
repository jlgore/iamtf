


variable "profile_name" {
  type    = string
  default = "default"
}

variable "bucket_name" {
  type    = string
  default = "mybucketname"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.0.100.0/24", "10.0.200.0/24"]

}

variable "pubilc_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["10.0.1.0/24", "10.0.10.0/24"]
}

variable "ssh_key_pair" {
  type        = string
  description = "Your ssh public key"
}

variable "db_username" {
  type        = string
  description = "RDS username"
  default     = "mariadb"
}