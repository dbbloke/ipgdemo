variable "name_prefix" {
  description = "Prefix added to all resource names"
  type        = string
  default     = "ipgdemo"
}

variable "environment" {
  description = "Environment identifier (e.g., staging, production)"
  type        = string
  default     = "production"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
}

variable "instance_type" {
  description = "EC2 instance type for the application"
  type        = string
  default     = "t3.micro"
}

variable "asg_desired_capacity" {
  description = "Number of instances in each Auto Scaling group"
  type        = number
  default     = 1
}

variable "ssh_allowed_cidr" {
  description = "CIDR blocks allowed SSH access to the instances"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "health_check_path" {
  description = "HTTP path used by the load balancer health check"
  type        = string
  default     = "/"
}

variable "additional_tags" {
  description = "Map of additional tags to add to resources"
  type        = map(string)
  default     = {}
}
