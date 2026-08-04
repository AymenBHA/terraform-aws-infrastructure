# DevSpace Troubleshooting Guide

## Overview

This document records the main issues encountered while building and deploying the DevSpace infrastructure.

The purpose is to document:

- The problem
- The root cause
- How it was diagnosed
- The solution applied

This helps during future debugging and technical interviews.

---

# 1. Nginx Service Failed to Start

## Problem

Ansible deployment failed during the Nginx start task:

```text
TASK [nginx : Start nginx]

fatal: FAILED!

Unable to start service nginx
```

---

## Investigation

Connect to the EC2 instance:

```bash
ssh -i ~/.ssh/id_rsa ec2-user@<EC2_IP>
```

Check Nginx configuration:

```bash
sudo nginx -t
```

Check service status:

```bash
sudo systemctl status nginx --no-pager -l
```

Check logs:

```bash
sudo journalctl -xeu nginx --no-pager
```

---

## Root Cause

The Nginx configuration was placed incorrectly.

The file contained:

```nginx
server {

    listen 80;

    server_name devspace.local;

}
```

but it was deployed directly inside:

```text
/etc/nginx/nginx.conf
```

The `nginx.conf` file requires a specific structure.

A `server` block cannot exist directly at the top level.

Error:

```text
server directive is not allowed here
```

---

## Solution

Move the virtual host configuration into:

```text
/etc/nginx/conf.d/devspace.conf
```

Example:

```nginx
server {

    listen 80;

    server_name devspace.local;

    root /usr/share/nginx/html;

}
```

Then test:

```bash
sudo nginx -t
```

Restart:

```bash
sudo systemctl restart nginx
```

---

# 2. Missing nginx.conf File

## Problem

Nginx failed with:

```text
open() "/etc/nginx/nginx.conf" failed (2: No such file or directory)
```

---

## Investigation

Command:

```bash
sudo nginx -t
```

Output:

```text
nginx: [emerg] open() "/etc/nginx/nginx.conf" failed
```

---

## Root Cause

The original Nginx configuration file was overwritten or removed.

The Nginx service expects:

```text
/etc/nginx/nginx.conf
```

to exist.

---

## Solution

Restore the default Nginx configuration.

Verify installation:

```bash
sudo dnf reinstall nginx -y
```

Check:

```bash
ls /etc/nginx/
```

Expected:

```text
nginx.conf
conf.d/
```

---

# 3. Terraform Selected Wrong Availability Zones

## Problem

Terraform created subnets in:

```text
us-east-1-wl1-atl-wlz-1

us-east-1-wl1-bna-wlz-1
```

Instead of:

```text
us-east-1a

us-east-1b
```

---

## Error

Subnet creation failed:

```text
InvalidParameterValue:
invalid value for parameter map-public-ip-on-launch
```

---

## Investigation

Check AWS availability zones:

```bash
aws ec2 describe-availability-zones \
--region us-east-1 \
--query "AvailabilityZones[*].[ZoneName,ZoneType,State]"
```

Output showed:

```text
wavelength-zone
```

instead of:

```text
availability-zone
```

---

## Root Cause

Terraform data source:

```hcl
data "aws_availability_zones" "available"
```

returned all available zones, including AWS Wavelength zones.

Wavelength zones are not normal availability zones and caused unexpected behavior.

---

## Solution

Filter only standard Availability Zones.

Example:

```hcl
data "aws_availability_zones" "available" {

  state = "available"

  filter {

    name = "opt-in-status"

    values = [
      "opt-in-not-required"
    ]

  }

}
```

Now Terraform selects:

```text
us-east-1a
us-east-1b
```

---

# 4. Terraform State Conflict

## Problem

Multiple Terraform executions can create conflicts.

Example:

Engineer A:

```text
terraform apply
```

Engineer B:

```text
terraform apply
```

at the same time.

---

## Root Cause

Both engineers modify the same infrastructure state.

Without locking:

- State corruption can happen
- Duplicate resources may be created
- Infrastructure drift can occur

---

## Solution

Use Terraform remote state:

```text
S3
 |
 |
 v

terraform.tfstate


DynamoDB

 |
 |
 v

State Lock
```

Terraform locks the state during operations.

---

# 5. Terraform Did Not Detect Existing Resources

## Problem

Terraform planned to create resources that already existed.

Example:

```text
Plan:

6 to add
```

---

## Root Cause

Terraform state was missing.

Terraform only knows resources through:

```text
terraform.tfstate
```

If the state file is lost:

Terraform cannot track existing infrastructure.

---

## Solution

Restore state or import resources.

Example:

```bash
terraform import aws_instance.web <instance_id>
```

For remote state:

```bash
terraform init
```

connects Terraform to S3 and retrieves the existing state.

---

# 6. Tainted Terraform Resources

## Problem

Terraform showed:

```text
resource is tainted, so must be replaced
```

---

## Meaning

A resource became marked as unhealthy because a previous operation failed.

Terraform will destroy and recreate it.

Example:

```text
-/+

destroy old resource

create new resource
```

---

## Solution

Check before applying:

```bash
terraform plan
```

If replacement is not required:

Remove taint:

```bash
terraform untaint <resource_address>
```

Example:

```bash
terraform untaint module.network.aws_subnet.public[0]
```

---

# 7. Ansible Python Interpreter Warning

## Warning

```text
Platform linux on host web1 is using discovered Python interpreter
```

---

## Meaning

Ansible automatically detected:

```text
/usr/bin/python3.9
```

The warning is informational.

The playbook still works.

---

## Solution

Optional:

Specify interpreter in inventory:

```ini
[webservers]

web1 ansible_host=<IP> \
ansible_user=ec2-user \
ansible_python_interpreter=/usr/bin/python3
```

---

# 8. Git Push Automation

## Problem

The deployment script automatically pushed every time.

This can be dangerous because:

- Mistakes can be pushed immediately
- Unfinished changes can reach GitHub

---

## Solution

Add confirmation before push.

Example:

```bash
read -p "Push changes to GitHub? (y/n): " choice

if [ "$choice" = "y" ]; then

    git push

fi
```

---

# Debugging Method Used

The general debugging workflow:

```text
Error message

      |
      v

Read logs

      |
      v

Identify failing component

      |
      v

Check configuration

      |
      v

Find root cause

      |
      v

Apply minimal fix

      |
      v

Test again
```

---

# Useful Debug Commands

## Terraform

```bash
terraform plan

terraform state list

terraform show

terraform output
```

---

## AWS

```bash
aws ec2 describe-instances

aws ec2 describe-subnets

aws s3 ls

aws dynamodb describe-table
```

---

## Linux

```bash
systemctl status <service>

journalctl -xeu <service>

cat <file>

ls -la <directory>
```

---

## Ansible

```bash
ansible all -m ping

ansible-playbook playbook.yml -v
```

---

