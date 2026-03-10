output "nginx_public_ip" {
  description = "Public IP of nginx / NAT instance (SSH entry point)"
  value       = aws_instance.nginx.public_ip
}

output "nginx_private_ip" {
  description = "Private IP of nginx"
  value       = aws_instance.nginx.private_ip
}

output "uptime_kuma_private_ip" {
  description = "Private IP of Uptime Kuma instance"
  value       = aws_instance.uptime_kuma.private_ip
}

output "prometheus_grafana_private_ip" {
  description = "Private IP of Prometheus/Grafana instance"
  value       = aws_instance.prometheus_grafana.private_ip
}
