module "networking" {
  source = "./modules/networking"

  project_name        = var.project_name
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  availability_zone   = var.availability_zone
}
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
}
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
}
module "ec2" {

  source = "./modules/ec2"

  project_name = var.project_name

  ami_id = var.ami_id

  instance_type = var.instance_type

  key_name = var.key_name

  public_subnet_id = module.networking.public_subnet_id

  security_group_id = module.security.security_group_id

  instance_profile_name = module.iam.instance_profile_name
}