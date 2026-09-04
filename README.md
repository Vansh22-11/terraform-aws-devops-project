# Terraform DevOps Project

## Project Overview

This project provisions AWS infrastructure using Terraform.

Infrastructure includes:

- Custom VPC
- Public Subnet
- Private Subnet
- Internet Gateway
- Route Table
- Security Group
- IAM Role
- IAM Instance Profile
- Ubuntu EC2 Instance

CI/CD:

VS Code → GitHub → Jenkins Dynamic EC2 Agent → Terraform → AWS → S3

## Monitoring

The deployment playbook installs Prometheus in Minikube from
`ansible/Kubernetes/prometheus.yml`.

Check Prometheus:

```bash
kubectl get pod -l app=prometheus
kubectl get service prometheus
curl http://$(minikube ip):30090/-/ready
```

After Jenkins applies the Terraform security-group and Nginx changes, open the
Prometheus web interface at:

```text
http://<EC2_PUBLIC_IP>:9090
```

The EC2 Nginx proxy forwards port `9090` to the Minikube Prometheus service on
port `30090`. No SSH tunnel is required.

Prometheus discovers pods that have these annotations and expose a metrics
endpoint:

```yaml
prometheus.io/scrape: "true"
prometheus.io/path: "/metrics"
prometheus.io/port: "8080"
```

Prometheus cannot collect application metrics from a pod that does not expose
a Prometheus-compatible metrics endpoint. The current Nginx application serves
HTML only, so it is not automatically a metrics target.