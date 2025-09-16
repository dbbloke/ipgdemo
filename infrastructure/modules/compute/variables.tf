variable "name_prefix" {
  description = "Prefix for compute resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC identifier"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for Auto Scaling groups"
  type        = list(string)
}

variable "alb_subnet_ids" {
  description = "Subnets where the load balancer will be deployed"
  type        = list(string)
  default     = []
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "asg_desired_capacity" {
  description = "Desired instance count in each Auto Scaling group"
  type        = number
  default     = 1
}

variable "ssh_allowed_cidr" {
  description = "CIDR blocks allowed to SSH to instances"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "health_check_path" {
  description = "HTTP health-check path"
  type        = string
  default     = "/"
}

variable "ami_id" {
  description = "Optional AMI ID to use for the launch template"
  type        = string
  default     = ""
}

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
