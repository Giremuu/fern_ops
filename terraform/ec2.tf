data "aws_ami" "ubuntu_2404" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ─── nginx (public) ───────────────────────────────────────────────────────────
# Also acts as NAT instance for the private subnet
# source_dest_check = false is mandatory for NAT Instance to work
# IP forwarding and iptables MASQUERADE are configured by the nginx Ansible role

resource "aws_instance" "nginx" {
  ami                         = data.aws_ami.ubuntu_2404.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.public.id]
  key_name                    = "WSL-Kali-PC-Fixe"
  associate_public_ip_address = true
  source_dest_check           = false

  tags = { Name = "${var.project_name}-nginx" }
}

# ─── Uptime Kuma (private) ────────────────────────────────────────────────────

resource "aws_instance" "uptime_kuma" {
  ami                    = data.aws_ami.ubuntu_2404.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private.id]
  key_name               = "WSL-Kali-PC-Fixe"

  tags = { Name = "${var.project_name}-uptime-kuma" }
}

# ─── Prometheus + Grafana (private) ──────────────────────────────────────────

resource "aws_instance" "prometheus_grafana" {
  ami                    = data.aws_ami.ubuntu_2404.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private.id]
  key_name               = "WSL-Kali-PC-Fixe"

  tags = { Name = "${var.project_name}-prometheus-grafana" }
}
