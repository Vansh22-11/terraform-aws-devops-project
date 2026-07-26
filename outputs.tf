output "vpc_id" {

  value = module.networking.vpc_id

}

output "public_subnet_id" {

  value = module.networking.public_subnet_id

}

output "private_subnet_id" {

  value = module.networking.private_subnet_id

}

output "security_group_id" {

  value = module.security.security_group_id

}

output "instance_profile_name" {

  value = module.iam.instance_profile_name

}

output "ec2_instance_id" {

  value = module.ec2.instance_id

}

output "ec2_public_ip" {

  value = module.ec2.public_ip

}

output "ec2_private_ip" {

  value = module.ec2.private_ip

}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecr_repository_name" {
  value = module.ecr.repository_name
}