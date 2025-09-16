environment          = "production"
region               = "us-east-1"
name_prefix          = "ipgdemo"
vpc_cidr             = "10.20.0.0/16"
instance_type        = "t3.small"
asg_desired_capacity = 2
ssh_allowed_cidr     = ["203.0.113.0/24"]
health_check_path    = "/"
additional_tags = {
  Owner       = "platform-team"
  CostCenter  = "1234"
}
