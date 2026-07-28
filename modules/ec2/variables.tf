variable "project_name" {

  type = string

}

variable "ami_id" {

  type = string

}

variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "m7i-flex.large"
}

variable "key_name" {

  type = string

}

variable "public_subnet_id" {

  type = string

}

variable "security_group_id" {

  type = string

}

variable "instance_profile_name" {

  type = string

}

variable "associate_public_ip" {
  description = "Associate Public IP with EC2"
  type        = bool
  default     = true
}