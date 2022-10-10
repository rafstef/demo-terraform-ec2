

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
  count = "${lookup(local.backend_instance_count, terraform.workspace)}"
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 4.1.1"

  name = "${lookup(local.resource_prefix, terraform.workspace)}-frontend-${lookup(local.env, terraform.workspace)}-${count.index}"

  ami                    =  data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = "cis-italy"
  monitoring             = true
  vpc_security_group_ids = [data.terraform_remote_state.networking.outputs.security_group]
  subnet_id              = data.terraform_remote_state.networking.outputs.public_subnets[count.index]

  tags = {
    Terraform   = "true"
    Environment = "${lookup(local.env, terraform.workspace)}"
  }
}

module "backend_ec2" {
  count = "${lookup(local.backend_instance_count, terraform.workspace)}"
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 4.1.1"

  name = "${lookup(local.resource_prefix, terraform.workspace)}-backend-${lookup(local.env, terraform.workspace)}-${count.index}"

  ami                    =  data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = "cis-italy"
  monitoring             = true
  vpc_security_group_ids = [data.terraform_remote_state.networking.outputs.security_group]
  subnet_id              = data.terraform_remote_state.networking.outputs.private_subnets[count.index]

  tags = {
    Terraform   = "true"
    Environment = "${lookup(local.env, terraform.workspace)}"
  }
}

