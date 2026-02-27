# Fern_Ops

Automated AWS Infrastructure & Observability
Start : January 2026

## Presentation

Fern_Ops is a cloud project focused on Infrastructure-as-Code (IaC). The goal is to automatically provision an AWS infrastructure using Terraform, then configure and deploy a complete observability stack using Ansible.

## Stack
- AWS & AWS CLI
- Terraform
- Ansible
- Prometheus
- Grafana
- UpTime Kuma
- NGINX
- Let's encrypt

## Structure of the project

```markdown
fern_ops/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── ansible/
│   ├── inventory/
│   ├── playbook.yml
│   └── roles/
│       ├── prometheus/
│       ├── grafana/
│       ├── uptime_kuma/
│       └── nginx_https/
├── docs/
│   ├── ...
└── README.md
```

## Workflow

1. Provisionning
- cd terraform
- terraform init
- terraform fmt
- terraform plan
- terraform validate
- terraform apply

2. Configuration des services
- cd ansible
- ansible-playbook -i inventory/aws.ini playbook.yml --check --vvv
- ansible-playbook -i inventory/aws.ini playbook.yml
