###############################################################################
# main.tf — FernOps
# Gwilherm LE GALLIC
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

###############################################################################
# SUBNETS
###############################################################################

# Public subnet (bastion + nginx)
resource "aws_subnet" "public" {
  vpc_id                  = var.aws_vpc_id
  cidr_block              = var.public_subnet_cidr_block
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-subnet-${var.environment}"
    Tier = "public"
  })
}

# Private subnet (monitoring + uptime)
resource "aws_subnet" "private" {
  vpc_id                  = var.aws_vpc_id
  cidr_block              = var.private_subnet_cidr_block
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-private-subnet-${var.environment}"
    Tier = "private"
  })
}

###############################################################################
# INTERNET + ROUTING (PUBLIC)
###############################################################################

# Internet Gateway (for public subnet)
resource "aws_internet_gateway" "gateway" {
  vpc_id = var.aws_vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-igw-${var.environment}"
  })
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = var.aws_vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-rt-public-${var.environment}"
  })
}

# Associate public RT to public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

###############################################################################
# NAT (PRIVATE OUTBOUND)
###############################################################################

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-eip-nat-${var.environment}"
  })
}

# NAT Gateway must be in PUBLIC subnet
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-nat-${var.environment}"
  })

  depends_on = [aws_internet_gateway.nat_gateway]
}

# Private route table > NAT
resource "aws_route_table" "private" {
  vpc_id = var.aws_vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-rt-private-${var.environment}"
  })
}

# Associate private RT to private subnet
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

###############################################################################
# SECURITY GROUPS
###############################################################################

# Bastion SG: SSH only (from allowed CIDRs)
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-sg-bastion-${var.environment}"
  description = "Bastion: allow SSH from allowed CIDRs"
  vpc_id      = var.aws_vpc_id

  ingress {
    description = "SSH to bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-sg-bastion-${var.environment}"
  })
}

# Nginx SG: public web + optional SSH only from bastion
resource "aws_security_group" "nginx" {
  name        = "${var.project_name}-sg-nginx-${var.environment}"
  description = "Nginx reverse proxy: allow HTTP/HTTPS from internet"
  vpc_id      = var.aws_vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    description     = "SSH to nginx (only from bastion)"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-sg-nginx-${var.environment}"
  })
}

# Private SG: SSH only from bastion, app ports only from nginx
resource "aws_security_group" "private" {
  name        = "${var.project_name}-sg-private-${var.environment}"
  description = "Private instances: SSH only from bastion; app ports only from nginx"
  vpc_id      = var.aws_vpc_id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    description     = "Grafana (3000) from nginx"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx.id]
  }

  ingress {
    description     = "Uptime Kuma (3001) from nginx"
    from_port       = 3001
    to_port         = 3001
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-sg-private-${var.environment}"
  })
}