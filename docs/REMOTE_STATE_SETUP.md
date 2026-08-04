# Terraform Remote State Setup (S3 + DynamoDB)

## Objective

Configure Terraform remote state using AWS S3 and DynamoDB.

The goal is to avoid storing Terraform state locally and allow safe collaboration between engineers.

Benefits:

- Centralized Terraform state storage
- Shared state between team members
- State locking
- State version recovery
- Better security

---

# Architecture

```text
Terraform
    |
    |
    v

Amazon S3
(terraform.tfstate storage)

    |
    |
    v

DynamoDB
(state locking)
```

---

# 1. Create S3 Bucket

The S3 bucket stores the Terraform state file.

Example:

```text
devspace-aymen-terraform-state
```

The state file:

```text
terraform.tfstate
```

is stored remotely inside this bucket.

---

## Create Bucket

```bash
aws s3 mb s3://devspace-aymen-terraform-state \
--region us-east-1
```

---

## Enable Versioning

Versioning allows recovery of previous Terraform state versions.

```bash
aws s3api put-bucket-versioning \
--bucket devspace-aymen-terraform-state \
--versioning-configuration Status=Enabled
```

---

## Enable Encryption

Terraform state may contain sensitive information.

Enable server-side encryption:

```bash
aws s3api put-bucket-encryption \
--bucket devspace-aymen-terraform-state \
--server-side-encryption-configuration \
'{
  "Rules": [
    {
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }
  ]
}'
```

---

# 2. Create DynamoDB Lock Table

DynamoDB prevents multiple Terraform operations from modifying the state simultaneously.

Example:

```text
terraform-state-lock
```

---

## Create Table

```bash
aws dynamodb create-table \
--table-name terraform-state-lock \
--attribute-definitions AttributeName=LockID,AttributeType=S \
--key-schema AttributeName=LockID,KeyType=HASH \
--billing-mode PAY_PER_REQUEST \
--region us-east-1
```

---

## Verify Table Status

```bash
aws dynamodb describe-table \
--table-name terraform-state-lock \
--query "Table.TableStatus"
```

Expected output:

```text
"ACTIVE"
```

---

# 3. Configure Terraform Backend

Create the file:

```text
backend.tf
```

Inside your Terraform project.

Add:

```hcl
terraform {

  backend "s3" {

    bucket = "devspace-aymen-terraform-state"

    key = "terraform.tfstate"

    region = "us-east-1"

    dynamodb_table = "terraform-state-lock"

    encrypt = true

  }

}
```

---

# 4. Initialize Terraform with Remote Backend

Run:

```bash
terraform init
```

Terraform will:

- Connect to the S3 bucket
- Configure the remote backend
- Enable state locking using DynamoDB
- Migrate local state if required

---

# 5. Verify Remote State

## Check Terraform Resources

```bash
terraform state list
```

Example:

```text
module.network.aws_vpc.main
module.network.aws_subnet.public[0]
module.network.aws_subnet.public[1]
module.compute.aws_instance.web
```

---

## Verify S3 Bucket

```bash
aws s3 ls
```

Example:

```text
2026-08-04 02:58:04 devspace-aymen-terraform-state
```

The bucket should contain:

```text
terraform.tfstate
```

---

# How Remote State Works

Before remote state:

```text
Engineer machine

terraform.tfstate
```

Problems:

- Different engineers may have different states
- State conflicts can happen
- Risk of incorrect infrastructure changes

---

After remote state:

```text
              Terraform
                  |
                  |
                  v

        +--------------------+
        |        S3          |
        |                    |
        | terraform.tfstate  |
        +--------------------+

                  |
                  |
                  v

        +--------------------+
        |     DynamoDB       |
        |                    |
        | terraform-state-   |
        | lock               |
        +--------------------+
```

---
