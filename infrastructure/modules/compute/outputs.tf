output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.this.dns_name
}

output "alb_arn" {
  description = "ARN of the ALB"
  value       = aws_lb.this.arn
}

output "alb_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "blue_target_group_arn" {
  description = "Target group ARN for the blue environment"
  value       = aws_lb_target_group.blue.arn
}

output "green_target_group_arn" {
  description = "Target group ARN for the green environment"
  value       = aws_lb_target_group.green.arn
}

output "blue_asg_name" {
  description = "Name of the blue Auto Scaling group"
  value       = aws_autoscaling_group.blue.name
}

output "green_asg_name" {
  description = "Name of the green Auto Scaling group"
  value       = aws_autoscaling_group.green.name
}
