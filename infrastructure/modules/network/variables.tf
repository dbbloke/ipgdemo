variable "name_prefix" {
  description = "Prefix used for naming network resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "az_count" {
  description = "Number of availability zones to span"
  type        = number
  default     = 2
}

variable "public_subnet_cidr_bits" {
  description = "Number of additional prefix bits for public subnets"
  type        = number
  default     = 8
}
