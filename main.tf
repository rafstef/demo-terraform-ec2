

terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "4.23.0"
        }  
    }
    backend "s3" {
        bucket = "202210-demo-terraform"
        key    = "demo-terraform-ec2"
        region = "eu-central-1"
    }
}

data "terraform_remote_state" "networking" {
  workspace = "${terraform.workspace}"
  backend = "s3"
  config = {
    bucket = "202210-demo-terraform"
    key    = "demo-terraform-vpc"
    region = "eu-central-1"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = "true"
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}



module "frontend_ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 4.1.1"

  name = "demo-terraform-ec2-frontend-${lookup(local.env, terraform.workspace)}"

  ami                    =  data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  key_name               = "cis-italy"
  monitoring             = true
  vpc_security_group_ids = []
  subnet_id              = data.terraform_remote_state.networking.outputs.private_subnets[0]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

