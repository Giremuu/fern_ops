# ─── Public Security Group (nginx + NAT instance) ────────────────────────────

resource "aws_security_group" "public" {
  name        = "${var.project_name}-sg-pub"
  description = "Public instance: Nginx, NAT, SSH"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.project_name}-sg-pub" }
}

resource "aws_vpc_security_group_ingress_rule" "pub_icmp" {
  security_group_id = aws_security_group.public.id
  description       = "ICMP from my IP"
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = var.my_ip
}

resource "aws_vpc_security_group_ingress_rule" "pub_ssh" {
  security_group_id = aws_security_group.public.id
  description       = "SSH from my IP"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.my_ip
}

resource "aws_vpc_security_group_ingress_rule" "pub_http" {
  security_group_id = aws_security_group.public.id
  description       = "HTTP"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "pub_https" {
  security_group_id = aws_security_group.public.id
  description       = "HTTPS"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

# Required so the NAT instance accepts forwarded traffic from private instances
resource "aws_vpc_security_group_ingress_rule" "pub_from_private" {
  security_group_id = aws_security_group.public.id
  description       = "All traffic from private subnet (NAT forwarding)"
  ip_protocol       = "-1"
  cidr_ipv4         = "192.168.3.16/28"
}

resource "aws_vpc_security_group_egress_rule" "pub_egress" {
  security_group_id = aws_security_group.public.id
  description       = "All outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ─── Private Security Group (Uptime Kuma, Prometheus, Grafana) ───────────────

resource "aws_security_group" "private" {
  name        = "${var.project_name}-sg-priv"
  description = "Private instances: Uptime Kuma, Prometheus, Grafana"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.project_name}-sg-priv" }
}

resource "aws_vpc_security_group_ingress_rule" "priv_icmp" {
  security_group_id            = aws_security_group.private.id
  description                  = "ICMP from public SG"
  ip_protocol                  = "icmp"
  from_port                    = -1
  to_port                      = -1
  referenced_security_group_id = aws_security_group.public.id
}

resource "aws_vpc_security_group_ingress_rule" "priv_ssh" {
  security_group_id            = aws_security_group.private.id
  description                  = "SSH from public SG"
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  referenced_security_group_id = aws_security_group.public.id
}

resource "aws_vpc_security_group_ingress_rule" "priv_grafana" {
  security_group_id            = aws_security_group.private.id
  description                  = "Grafana from public SG"
  ip_protocol                  = "tcp"
  from_port                    = 3000
  to_port                      = 3000
  referenced_security_group_id = aws_security_group.public.id
}

resource "aws_vpc_security_group_ingress_rule" "priv_prometheus" {
  security_group_id            = aws_security_group.private.id
  description                  = "Prometheus from public SG"
  ip_protocol                  = "tcp"
  from_port                    = 9090
  to_port                      = 9090
  referenced_security_group_id = aws_security_group.public.id
}

resource "aws_vpc_security_group_ingress_rule" "priv_uptime_kuma" {
  security_group_id            = aws_security_group.private.id
  description                  = "Uptime Kuma from public SG"
  ip_protocol                  = "tcp"
  from_port                    = 3001
  to_port                      = 3001
  referenced_security_group_id = aws_security_group.public.id
}

resource "aws_vpc_security_group_egress_rule" "priv_egress" {
  security_group_id = aws_security_group.private.id
  description       = "All outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
