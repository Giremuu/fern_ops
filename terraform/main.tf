###############################################################################
# main.tf — FernOps (ALL PUBLIC, NO BASTION, NO NAT)
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
# PUBLIC SUBNET ONLY
###############################################################################

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

###############################################################################
# INTERNET + ROUTING (PUBLIC)
###############################################################################

resource "aws_internet_gateway" "gateway" {
  vpc_id = var.aws_vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-igw-${var.environment}"
  })
}

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

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

###############################################################################
# SECURITY GROUPS (ALL PUBLIC)
###############################################################################

# SSH SG shared by all instances (key_name controls auth, SG controls who can try)
resource "aws_security_group" "ssh" {
  name        = "${var.project_name}-sg-ssh-${var.environment}"
  description = "Allow SSH from allowed CIDRs"
  vpc_id      = var.aws_vpc_id

  ingress {
    description = "SSH"
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
    Name = "${var.project_name}-sg-ssh-${var.environment}"
  })
}

# Nginx reverse proxy (public web)
resource "aws_security_group" "nginx" {
  name        = "${var.project_name}-sg-nginx-${var.environment}"
  description = "Nginx: allow HTTP/HTTPS"
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

# Monitoring (Grafana + Prometheus) exposed
resource "aws_security_group" "monitoring" {
  name        = "${var.project_name}-sg-monitoring-${var.environment}"
  description = "Monitoring: Grafana/Prometheus exposed"
  vpc_id      = var.aws_vpc_id

  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-sg-monitoring-${var.environment}"
  })
}

# Uptime Kuma exposed
resource "aws_security_group" "uptime" {
  name        = "${var.project_name}-sg-uptime-${var.environment}"
  description = "Uptime Kuma exposed"
  vpc_id      = var.aws_vpc_id

  ingress {
    description = "Uptime Kuma"
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-sg-uptime-${var.environment}"
  })
}