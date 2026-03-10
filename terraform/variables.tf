variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "fernops"
}

variable "my_ip" {
  description = "Public IP in CIDR notation"
  type        = string
  sensitive   = true
}
