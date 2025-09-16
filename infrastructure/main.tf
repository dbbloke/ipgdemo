locals {
  name_prefix = var.name_prefix
}

module "network" {
  source      = "./modules/network"
  name_prefix = local.name_prefix
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
  az_count    = var.az_count
}

module "compute" {
  source              = "./modules/compute"
  name_prefix         = local.name_prefix
  environment         = var.environment
  vpc_id              = module.network.vpc_id
  subnet_ids          = module.network.public_subnet_ids
  alb_subnet_ids      = module.network.public_subnet_ids
  instance_type       = var.instance_type
  asg_desired_capacity = var.asg_desired_capacity
  ssh_allowed_cidr    = var.ssh_allowed_cidr
  health_check_path   = var.health_check_path
  additional_tags     = var.additional_tags
}
