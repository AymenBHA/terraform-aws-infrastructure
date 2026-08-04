# DevSpace Infrastructure Architecture

## Overview

This document explains the architecture and workflow of the DevSpace infrastructure project.

The project uses:

- Terraform for Infrastructure as Code (IaC)
- AWS for cloud infrastructure
- Ansible for server configuration
- Nginx as the web server
- Bash automation for the complete deployment workflow

The goal is to automatically create an AWS environment, configure a web server, and deploy a website with minimal manual intervention.

---

# High-Level Architecture

```text
                         Developer

                            |
                            |
                            v

                         setup.sh

                            |
            +---------------+---------------+
            |                               |
            v                               v

       Terraform                       Ansible
            |                               |
            |                               |
            v                               v

     AWS Infrastructure              Server Configuration


            |
            |
            v


                     AWS Cloud Environment


                         VPC

                          |
                          |

              +-----------+-----------+
              |                       |
              v                       v

        Public Subnet 1        Public Subnet 2

              |
              |
              v

             EC2 Instance

              |
              |
              v

             Nginx

              |
              |
              v

           Website Page
```

---

# Deployment Workflow

The complete deployment follows these steps:

```text
Developer runs:

./setup.sh

        |
        v

Check dependencies

        |
        v

Terraform initialization

        |
        v

Connect to remote backend

        |
        |
        +--> S3 stores terraform.tfstate
        |
        +--> DynamoDB locks state

        |
        v

Terraform creates AWS resources

        |
        v

Retrieve EC2 public IP

        |
        v

Generate Ansible inventory

        |
        v

Ansible connects through SSH

        |
        v

Install and configure Nginx

        |
        v

Deploy website

        |
        v

Application available
```

---

# Terraform Architecture

Terraform is responsible for creating the AWS infrastructure.

## Terraform Structure

```text
terraform-aws-infrastructure/

├── modules/
│
├── network/
│   ├── VPC
│   ├── Subnets
│   ├── Internet Gateway
│   └── Route Tables
│
└── compute/
    ├── EC2 Instance
    └── Security Group
```

---

# Network Architecture

The project creates a custom VPC.

```text
                 Internet

                    |
                    |
                    v

          Internet Gateway

                    |
                    |
                    v

                  VPC

                    |
        +-----------+-----------+
        |                       |
        v                       v

 Public Subnet 1        Public Subnet 2

        |
        |
        v

   EC2 Instance
```

---

# VPC Components

## VPC

Provides an isolated AWS network environment.

Example:

```text
10.0.0.0/16
```

---

## Public Subnets

The EC2 instance runs inside public subnets.

Characteristics:

- Have access to the Internet Gateway
- Can receive public IP addresses
- Used for public-facing services

---

## Internet Gateway

Allows communication between:

```text
Internet <----> AWS VPC
```

---

## Route Table

Controls network traffic routing.

Example:

```text
0.0.0.0/0

        |
        v

Internet Gateway
```

This allows outbound Internet access.

---

# Terraform Remote State Architecture

Terraform state is stored remotely.

```text
              Terraform

                  |
                  |

                  v

        +----------------+
        |      S3        |
        |                |
        | terraform.tfstate |
        +----------------+

                  |
                  |

                  v

        +----------------+
        |   DynamoDB     |
        |                |
        | State Locking  |
        +----------------+
```

## S3 Responsibilities

- Store Terraform state
- Provide centralized state storage
- Maintain state versions

## DynamoDB Responsibilities

- Lock Terraform state
- Prevent concurrent modifications

---

# Ansible Architecture

Ansible configures the EC2 instance after Terraform deployment.

Workflow:

```text
Terraform

    |
    |
    v

EC2 Instance Created

    |
    |
    v

Terraform Output:

public_ip

    |
    |
    v

Generate inventory.ini

    |
    |
    v

Ansible SSH Connection

    |
    |
    v

Configure Server
```

---

# Ansible Role Structure

```text
ansible/

├── playbook.yml
│
└── roles/
    |
    └── nginx/
        |
        ├── tasks/
        |
        ├── handlers/
        |
        ├── templates/
        |
        ├── vars/
        |
        └── defaults/
```

---

# Nginx Deployment Flow

```text
Ansible

    |
    |
    v

Install Nginx

    |
    |
    v

Deploy configuration

/etc/nginx/conf.d/devspace.conf

    |
    |
    v

Deploy website

/usr/share/nginx/html/index.html

    |
    |
    v

Restart Nginx if configuration changed

    |
    |
    v

Running Web Server
```

---

# Security Design

The project uses:

## SSH Authentication

EC2 access is managed using an SSH private key.

Flow:

```text
Ansible Controller

        |
        |
        v

SSH Connection

        |
        |
        v

EC2 Instance
```

---

## Security Group

The EC2 instance uses a security group to control traffic.

Example rules:

```text
SSH     : Port 22
HTTP    : Port 80
```

Only required ports should be exposed.

---

# Design Decisions

## Why Terraform?

Terraform provides:

- Infrastructure automation
- Infrastructure version control
- Repeatable deployments
- Declarative infrastructure management

---

## Why Ansible?

Ansible provides:

- Server configuration automation
- Idempotent deployments
- Easy service management

---

## Why Separate Terraform and Ansible?

Terraform manages:

```text
Infrastructure
```

Examples:

- VPC
- EC2
- Security groups

Ansible manages:

```text
Configuration
```

Examples:

- Packages
- Services
- Configuration files

This separation follows common DevOps practices.

---

# Future Architecture Improvements

Possible improvements:

```text
Git Repository

        |
        v

CI/CD Pipeline

        |
        v

Terraform

        |
        v

AWS Infrastructure

        |
        v

Docker Containers

        |
        v

Kubernetes / ECS
```

Future additions:

- Docker container deployment
- Jenkins or GitHub Actions pipeline
- HTTPS with SSL certificates
- Monitoring with Prometheus and Grafana
