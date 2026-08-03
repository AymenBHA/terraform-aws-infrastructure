# DevSpace Infrastructure Deployment

## Overview

This project automates the provisioning and configuration of an AWS web server using:

* Terraform → Infrastructure provisioning
* Ansible → Server configuration
* Nginx → Web server deployment

The `setup.sh` script automates the complete workflow:

1. Checks and installs required tools.
2. Generates an SSH key if it does not exist.
3. Runs Terraform to create AWS infrastructure.
4. Retrieves Terraform outputs.
5. Generates the Ansible inventory automatically.
6. Runs Ansible playbooks.
7. Commits and pushes changes to GitHub.

---

# Project Structure

```text
terraform-aws-infrastructure/

├── setup.sh
├── SETUP.md
├── .gitignore
│
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
│
└── ansible/
    ├── ansible.cfg
    ├── inventory.ini (generated automatically)
    ├── playbook.yml
    └── roles/
        └── nginx/
```

Important:

* Terraform files are located at the repository root.
* Ansible files are located inside `/ansible`.
* Run `setup.sh` from the repository root.

---

# Requirements

The user needs:

* AWS account
* GitHub account
* Terraform
* Ansible
* Git
* AWS CLI

The script automatically installs Terraform and Ansible if they are missing.

---

# AWS Configuration

Before running the deployment, configure AWS credentials:

```bash
aws configure
```

Provide:

```
AWS Access Key ID
AWS Secret Access Key
Default AWS Region
Output format
```

Terraform uses these credentials to create AWS resources.

---

# Terraform Configuration

Terraform variables are configured in:

```text
terraform.tfvars
```

Example:

```hcl
region = "us-east-1"

instance_type = "t3.micro"

public_key_path = "/home/cloudshell-user/.ssh/id_rsa.pub"
```

## SSH Key

Terraform uses the public key:

```
id_rsa.pub
```

to create an AWS key pair.

The private key:

```
id_rsa
```

is used by Ansible to connect to the EC2 instance.

Flow:

```
Terraform
    |
    | uploads public key
    |
    v
EC2 authorized_keys

Ansible
    |
    | uses private key
    |
    v
SSH connection
```

---

# Terraform Outputs

Terraform exposes information needed by Ansible.

Example:

```hcl
output "public_ip" {
  value = aws_instance.web.public_ip
}
```

The deployment script retrieves this value:

```bash
terraform output -raw public_ip
```

and uses it to generate:

```
ansible/inventory.ini
```

Example:

```ini
[webservers]

web1 ansible_host=<EC2_PUBLIC_IP> \
ansible_user=ec2-user \
ansible_ssh_private_key_file=~/.ssh/id_rsa
```

---

# Running the Deployment

Clone the repository:

```bash
git clone <repository-url>
```

Enter the project:

```bash
cd terraform-aws-infrastructure
```

Make the script executable:

```bash
chmod +x setup.sh
```

Run:

```bash
./setup.sh
```

The only manual step during execution is entering the Git commit message.

---

# GitHub Authentication

The script does not store GitHub tokens.

Before pushing changes, authenticate using your own account:

Recommended:

```bash
gh auth login
```

Never commit:

* GitHub tokens
* AWS credentials
* SSH private keys

---

# Deployment Flow

```
User runs setup.sh

        |
        v

Install dependencies

        |
        v

Terraform

        |
        |
        +--> Create VPC
        +--> Create Security Group
        +--> Create EC2

        |
        v

Terraform output

        |
        v

Generate Ansible inventory

        |
        v

Ansible

        |
        |
        +--> Install Nginx
        +--> Deploy configuration
        +--> Deploy website

        |
        v

Git commit and push
```

---

# Troubleshooting

## Nginx fails to start

Check:

```bash
sudo nginx -t
```

Then:

```bash
sudo systemctl status nginx
```

Logs:

```bash
sudo journalctl -xeu nginx
```

---

## Terraform output missing

Example error:

```
Output "web_public_ip" not found
```

Check available outputs:

```bash
terraform output
```

Use the correct output name in `setup.sh`.

Example:

```bash
terraform output -raw public_ip
```

---

# Security Notes

The following files must never be committed:

```
*.tfstate
.terraform/
.aws/
id_rsa
*.pem
.env
```

They are excluded using `.gitignore`.

