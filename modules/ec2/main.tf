resource "aws_instance" "ubuntu" {

  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.public_subnet_id
  key_name      = var.key_name

  vpc_security_group_ids = [
    var.security_group_id
  ]

  iam_instance_profile = var.instance_profile_name

  user_data = file("${path.root}/userdata.sh")

  tags = {
    Name = "${var.project_name}-server"
  }
}