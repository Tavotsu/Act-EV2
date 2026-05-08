terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ============================================================
# VARIABLES
# ============================================================

variable "region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "ami_id" {
  description = "AMI para las instancias EC2 (Amazon Linux 2023)"
  type        = string
  default     = "ami-0c101f26f147fa7fd"
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Nombre del key pair para SSH"
  type        = string
  default     = "vockey"
}

variable "project_name" {
  description = "Nombre del proyecto para etiquetas"
  type        = string
  default     = "tienda-perritos"
}

# ============================================================
# PROVIDER
# ============================================================

provider "aws" {
  region = var.region
}

# ============================================================
# VPC
# ============================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "${var.project_name}-vpc" }
}

# ============================================================
# SUBREDES
# ============================================================

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = { Name = "${var.project_name}-public" }
}

resource "aws_subnet" "priv_app" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.region}a"

  tags = { Name = "${var.project_name}-priv-app" }
}

resource "aws_subnet" "priv_data" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.region}a"

  tags = { Name = "${var.project_name}-priv-data" }
}

# ============================================================
# INTERNET GATEWAY + NAT GATEWAY
# ============================================================

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${var.project_name}-nat-eip" }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags          = { Name = "${var.project_name}-nat" }

  depends_on = [aws_internet_gateway.igw]
}

# ============================================================
# TABLAS DE RUTAS
# ============================================================

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "pub_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = { Name = "${var.project_name}-private-rt" }
}

resource "aws_route_table_association" "app_assoc" {
  subnet_id      = aws_subnet.priv_app.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "data_assoc" {
  subnet_id      = aws_subnet.priv_data.id
  route_table_id = aws_route_table.private_rt.id
}

# ============================================================
# GRUPOS DE SEGURIDAD
# ============================================================

resource "aws_security_group" "grupoWeb" {
  name   = "${var.project_name}-sg-web"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sg-web" }
}

resource "aws_security_group" "grupoApp" {
  name   = "${var.project_name}-sg-app"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "SSH desde Web"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.grupoWeb.id]
  }

  ingress {
    description     = "HTTP desde Web"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.grupoWeb.id]
  }

  ingress {
    description     = "Backend desde Web"
    from_port       = 3001
    to_port         = 3001
    protocol        = "tcp"
    security_groups = [aws_security_group.grupoWeb.id]
  }

  ingress {
    description     = "ICMP desde Web"
    from_port       = -1
    to_port         = -1
    protocol        = "icmp"
    security_groups = [aws_security_group.grupoWeb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sg-app" }
}

resource "aws_security_group" "grupoData" {
  name   = "${var.project_name}-sg-data"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "MySQL desde App"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.grupoApp.id]
  }

  ingress {
    description     = "ICMP desde App"
    from_port       = -1
    to_port         = -1
    protocol        = "icmp"
    security_groups = [aws_security_group.grupoApp.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sg-data" }
}

# ============================================================
# USER DATA (Docker en cada instancia)
# ============================================================

locals {
  user_data = <<-EOT
    #!/bin/bash
    set -e
    dnf update -y
    dnf install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user
  EOT
}

# ============================================================
# INSTANCIAS EC2
# ============================================================

resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.grupoWeb.id]
  iam_instance_profile   = "LabInstanceProfile"
  key_name               = var.key_name
  user_data              = local.user_data

  tags = { Name = "${var.project_name}-web" }
}

resource "aws_instance" "app" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.priv_app.id
  vpc_security_group_ids = [aws_security_group.grupoApp.id]
  iam_instance_profile   = "LabInstanceProfile"
  key_name               = var.key_name
  user_data              = local.user_data

  tags = { Name = "${var.project_name}-app" }
}

resource "aws_instance" "data" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.priv_data.id
  vpc_security_group_ids = [aws_security_group.grupoData.id]
  iam_instance_profile   = "LabInstanceProfile"
  key_name               = var.key_name
  user_data              = local.user_data

  tags = { Name = "${var.project_name}-data" }
}

# ============================================================
# OUTPUTS
# ============================================================

output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}

output "web_public_ip" {
  description = "IP pública de la instancia Web (Frontend)"
  value       = aws_instance.web.public_ip
}

output "app_private_ip" {
  description = "IP privada de la instancia App (Backend)"
  value       = aws_instance.app.private_ip
}

output "data_private_ip" {
  description = "IP privada de la instancia Data (DB)"
  value       = aws_instance.data.private_ip
}
