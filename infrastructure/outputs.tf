output "region" {
  description = "AWS region"
  value       = var.region
}

output "alb_dns_name" {
  description = "DNS name of the application load balancer"
  value       = module.compute.alb_dns_name
}

output "alb_listener_arn" {
  description = "Listener ARN used for traffic switching"
  value       = module.compute.alb_listener_arn
}

output "blue_target_group_arn" {
  description = "Target group ARN for the blue environment"
  value       = module.compute.blue_target_group_arn
}

output "green_target_group_arn" {
  description = "Target group ARN for the green environment"
  value       = module.compute.green_target_group_arn
}

output "blue_asg_name" {
  description = "Auto Scaling group name for the blue environment"
  value       = module.compute.blue_asg_name
}

output "green_asg_name" {
  description = "Auto Scaling group name for the green environment"
  value       = module.compute.green_asg_name
}
