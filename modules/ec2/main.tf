resource "aws_instance" "ubuntu" {

  ami = var.ami_id

  instance_type = var.instance_type

  subnet_id = var.public_subnet_id

  associate_public_ip_address = var.associate_public_ip

  key_name = var.key_name

  vpc_security_group_ids = [
    var.security_group_id
  ]

  iam_instance_profile = var.instance_profile_name

  user_data = file("${path.root}/userdata.sh")

  monitoring = true

  metadata_options {

    http_endpoint = "enabled"

    http_tokens = "required"

  }

  root_block_device {

    volume_size = 23

    volume_type = "gp3"

    delete_on_termination = true

    encrypted = true

  }

  lifecycle {

    ignore_changes = [
      associate_public_ip_address
    ]

  }

  tags = {

    Name = "${var.project_name}-server"

    Environment = "Dev"

    ManagedBy = "Terraform"

  }

}