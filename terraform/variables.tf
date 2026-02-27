###############################################################################
# variables.tf
###############################################################################

variable "project_name" {
  type        = string
  description = "Project name prefix"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, lab, prod)"
}

variable "tags" {
  type        = map(string)
  description = "Extra tags to apply to all resources"
  default     = {}
}

variable "aws_region" {
  type        = string
  description = "AWS region (e.g., eu-west-3)"
}

variable "availability_zone" {
  type        = string
  description = "AWS availability zone (e.g., eu-west-3a)"
}

variable "aws_vpc_id" {
  type        = string
  description = "Existing VPC ID where resources will be created"
}

variable "public_subnet_cidr_block" {
  type        = string
  description = "CIDR for public subnet (e.g., 10.0.1.0/24)"
}

variable "private_subnet_cidr_block" {
  type        = string
  description = "CIDR for private subnet (e.g., 10.0.2.0/24)"
}

variable "ssh_cidr_blocks" {
  type        = list(string)
  description = "Allowed source CIDRs for inbound SSH to bastion"
}