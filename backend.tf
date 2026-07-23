terraform {

  backend "s3" {

    bucket       = "terraform-state-vansh-2026"
    key          = "terraform.tfstate"
    region       = "eu-north-1"

    use_lockfile = true

  }

}