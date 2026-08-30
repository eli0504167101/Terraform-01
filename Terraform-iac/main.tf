terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Terraform-VPC"
  }
}
data "aws_availability_zones" "available" {
  state = "available"
}


resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "Terraform-Public-Subnet"
  }

}
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "Terraform-Private-Subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Terraform-Internet-Gateway"
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Terraform-Public-Route-Table"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "Terraform-NAT-Elastic-IP"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "Terraform-NAT-Gateway"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Terraform-Private-Route-Table"
  }
}

resource "aws_route" "private_internet" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "frontend" {
  name        = "terraform-frontend-sg"
  description = "Security group for the frontend server"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "Terraform-Frontend-SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "frontend_http" {
  security_group_id = aws_security_group.frontend.id
  description       = "Allow HTTP from the internet"

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "frontend_ssh" {
  security_group_id = aws_security_group.frontend.id
  description       = "Allow SSH from the administrator IP"

  cidr_ipv4   = "188.64.206.159/32"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "frontend_outbound" {
  security_group_id = aws_security_group.frontend.id
  description       = "Allow all outbound traffic"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_security_group" "backend" {
  name        = "terraform-backend-sg"
  description = "Security group for the backend server"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "Terraform-Backend-SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "backend_application" {
  security_group_id = aws_security_group.backend.id
  description       = "Allow application traffic from the frontend"

  referenced_security_group_id = aws_security_group.frontend.id
  from_port                    = 5000
  to_port                      = 5000
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "backend_outbound" {
  security_group_id = aws_security_group.backend.id
  description       = "Allow all outbound traffic"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_key_pair" "terraform" {
  key_name   = "terraform-ec2-key"
  public_key = file(pathexpand("~/.ssh/aws-terraform-key.pub"))

  tags = {
    Name = "Terraform-EC2-Key"
  }
}

data "aws_ssm_parameter" "amazon_linux_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "frontend" {
  ami           = data.aws_ssm_parameter.amazon_linux_ami.value
  instance_type = "t3.micro"

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.frontend.id]
  associate_public_ip_address = true

  key_name  = aws_key_pair.terraform.key_name
  user_data = file("${path.module}/frontend-user-data.sh")

  tags = {
    Name = "Terraform-Frontend"
  }
}

resource "aws_vpc_security_group_ingress_rule" "backend_ssh" {
  security_group_id = aws_security_group.backend.id
  description       = "Allow SSH only through the frontend server"

  referenced_security_group_id = aws_security_group.frontend.id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
}

resource "aws_instance" "backend" {
  ami           = data.aws_ssm_parameter.amazon_linux_ami.value
  instance_type = "t3.micro"

  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.backend.id]
  associate_public_ip_address = false

  key_name  = aws_key_pair.terraform.key_name
  user_data = file("${path.module}/backend-user-data.sh")

  tags = {
    Name = "Terraform-Backend"
  }
}