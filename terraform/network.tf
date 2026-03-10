# VPC
resource "aws_vpc" "main" {
  cidr_block           = "192.168.3.0/27"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "${var.project_name}-vpc" }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${var.project_name}-igw" }
}

# Public Subnet (192.168.3.0 - 192.168.3.15)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.3.0/28"
  availability_zone       = "eu-west-3a"
  map_public_ip_on_launch = true

  tags = { Name = "${var.project_name}-subnet-public" }
}

# Private Subnet (192.168.3.16 - 192.168.3.31)
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.3.16/28"
  availability_zone = "eu-west-3a"

  tags = { Name = "${var.project_name}-subnet-private" }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${var.project_name}-rt-public" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${var.project_name}-rt-private" }
}

# Default route via NAT Instance (nginx EC2)
# source_dest_check = false is required on the nginx instance
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nginx.primary_network_interface_id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
