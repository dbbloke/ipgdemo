environment          = "staging"
region               = "us-east-1"
name_prefix          = "ipgdemo-stg"
vpc_cidr             = "10.30.0.0/16"
instance_type        = "t3.micro"
asg_desired_capacity = 1
ssh_allowed_cidr     = ["0.0.0.0/0"]
health_check_path    = "/"
additional_tags = {
  Owner = "platform-team"
  Stage = "staging"
}
