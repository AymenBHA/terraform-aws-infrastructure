# Terraform AWS Infrastructure

A production-style AWS infrastructure project built with Terraform.

##



# Terraform Remote State Setup (S3 + DynamoDB)

## Objective

Configure Terraform remote state using AWS S3 and DynamoDB.

This setup provides:

* Centralized Terraform state storage.
* State sharing between engineers.
* State locking to prevent concurrent Terraform operations.
* State version history and recovery.

---

# 1. Create S3 Bucket for Terraform State

Terraform stores the infrastructure state file inside an S3 bucket.

Example:

```
devspace-aymen-terraform-state
```

The state file:

```
terraform.tfstate
```

will be stored remotely instead of locally.

---

## Create S3 Bucket

```bash
aws s3 mb s3://devspace-aymen-terraform-state \
--region us-east-1
```

---

## Enable S3 Versioning

Versioning allows recovery of previous versions of the Terraform state file.

```bash
aws s3api put-bucket-versioning \
--bucket devspace-aymen-terraform-state \
--versioning-configuration Status=Enabled
```

---

## Enable Server-Side Encryption

The Terraform state can contain sensitive information, so encryption is enabled.

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

# 2. Create DynamoDB Table for State Locking

Terraform uses DynamoDB to lock the state during operations.

Example:

```
terraform-state-lock
```

Purpose:

* Prevent multiple engineers from running Terraform at the same time.
* Avoid conflicting infrastructure changes.
* Protect the Terraform state consistency.

---

## Create DynamoDB Lock Table

```bash
aws dynamodb create-table \
--table-name terraform-state-lock \
--attribute-definitions AttributeName=LockID,AttributeType=S \
--key-schema AttributeName=LockID,KeyType=HASH \
--billing-mode PAY_PER_REQUEST \
--region us-east-1
```

---

## Verify DynamoDB Table Status

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

Create a file in the Terraform project:

```
backend.tf
```

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

* Connect to the S3 bucket.
* Configure the remote backend.
* Enable state locking through DynamoDB.
* Migrate the state if a previous local state exists.

---

# 5. Verify Remote State Configuration

## Check Terraform State Resources

```bash
terraform state list
```

Example output:

```text
module.network.aws_vpc.main
module.network.aws_subnet.public[0]
module.network.aws_subnet.public[1]
module.compute.aws_instance.web
```

---

## Verify S3 Bucket Exists

```bash
aws s3 ls
```

Example:

```text
2026-08-04 02:58:04 devspace-aymen-terraform-state
```

The bucket should contain:

```
terraform.tfstate
```

---

# Remote State Architecture

```
                 Terraform
                     |
                     |
                     v

          +---------------------+
          |        AWS S3       |
          |                     |
          |  terraform.tfstate  |
          +---------------------+

                     |
                     |
                     v

          +---------------------+
          |     DynamoDB        |
          |                     |
          | terraform-state-lock|
          |                     |
          +---------------------+
```

---

# Final Workflow

```
Create S3 Bucket
        |
        v
Enable Versioning
        |
        v
Enable Encryption
        |
        v
Create DynamoDB Lock Table
        |
        v
Create backend.tf
        |
        v
terraform init
        |
        v
terraform plan
        |
        v
terraform apply
```

