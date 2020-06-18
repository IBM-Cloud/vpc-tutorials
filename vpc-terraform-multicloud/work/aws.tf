provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

resource "aws_vpc" "vpc" {
  tags = {
    name = "aws_vpc__vpc"
  }
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "igw" {
  tags = {
    name = "aws_internet_gateway__igw"
  }
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "public" {
  tags = {
    name = "aws_route_table__public"
  }
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route" "public_internet_gateway" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  route_table_id         = aws_route_table.public.id
}

resource "aws_subnet" "public_0" {
  tags = {
    name = "aws_subnet__public_0"
  }
  vpc_id            = aws_vpc.vpc.id
  availability_zone = var.aws_zones[0]
  cidr_block        = "10.0.0.0/24"
}

resource "aws_route_table_association" "public_0" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_0.id
}

resource "aws_subnet" "public_1" {
  tags = {
    name = "aws_subnet__public_1"
  }
  vpc_id            = aws_vpc.vpc.id
  availability_zone = var.aws_zones[0]
  cidr_block        = "10.0.1.0/24"
}

resource "aws_route_table_association" "public_1" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_1.id
}

resource "aws_security_group" "sg1" {
  tags = {
    name = "aws_security_group__sg1"
  }
  description = "Security Group managed by Terraform2"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    protocol    = "tcp"
    description = "ssh from any ip address"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
  }
  ingress {
    protocol    = "tcp"
    description = "app can be accessed from any ip address"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 3000
    to_port     = 3000
  }
  egress {
    protocol    = "tcp"
    description = "install software over https"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    to_port     = 443
  }
  egress {
    protocol    = "tcp"
    description = "install software over http"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
  }
}

locals {
  ubuntu_18_04 = "ami-06f2f779464715dc5"
}

resource "aws_instance" "vsi1" {
  tags = {
    name = "aws_instance__vsi1"
  }
  ami                         = local.ubuntu_18_04
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_0.id
  vpc_security_group_ids      = [aws_security_group.sg1.id]
  associate_public_ip_address = true
  key_name                    = var.aws_ssh_key_name
  user_data                   = local.shared_app_user_data
}

resource "aws_eip" "vsi1" {
  instance = aws_instance.vsi1.id
  vpc      = true
}

output "aws_public_ip" {
  value = aws_eip.vsi1.public_ip
}

output "aws_private_ip" {
  value = aws_instance.vsi1.private_ip
}

output "aws_ssh" {
  value = "ssh ubuntu@${aws_eip.vsi1.public_ip}"
}

