# DevSpace Infrastructure Setup Script

## Overview

`setup.sh` automates the complete deployment workflow:

1. Checks required tools.
2. Creates an SSH key if it does not exist.
3. Configures Terraform.
4. Creates AWS infrastructure.
5. Retrieves Terraform outputs.
6. Generates Ansible inventory automatically.
7. Runs Ansible configuration.
8. Commits and pushes changes to GitHub.

---

# Requirements

Before running the script, install:

* Terraform
* Ansible
* Git
* AWS CLI

The user must also have valid AWS credentials configured.

Example:

```bash
aws configure
```

Required values:

* AWS Access Key ID
* AWS Secret Access Key
* Default AWS Region

---

# User Configuration Required

## 1. Git identity

Replace these values in `setup.sh`:

```bash
git config --global user.email "YOUR_EMAIL"
git config --global user.name "YOUR_USERNAME"
```

Example:

```bash
git config --global user.email "example@gmail.com"
git config --global user.name "username"
```

---

## 2. GitHub authentication

The script does not store GitHub tokens.

The user must authenticate manually before pushing.

Recommended:

```bash
gh auth login
```

or configure Git credentials using GitHub's recommended authentication method.

---

## 3. Terraform variables

Before running:

```bash
terraform apply
```

verify your Terraform variables.

Example:

```text
terraform.tfvars
```

contains environment-specific values such as:

* AWS region
* Instance type
* SSH public key path

---

# Running the Deployment

Clone the repository:

```bash
git clone <repository-url>
```

Enter the directory:

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

# Architecture Flow

```
Terraform
    |
    | Creates AWS infrastructure
    |
    v
EC2 Instance
    |
    | SSH public key installed
    |
    v
Ansible
    |
    | Uses private SSH key
    |
    v
Server configuration
```

---

# Important Security Notes

Never commit:

* Private SSH keys
* AWS credentials
* GitHub tokens
* Terraform state files

These are excluded using `.gitignore`.

