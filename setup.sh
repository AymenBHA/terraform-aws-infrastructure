#!/bin/bash

set -e

echo "🚀 Starting DevSpace deployment"

REPO_ROOT=$(pwd)

TERRAFORM_DIR="$REPO_ROOT"
ANSIBLE_DIR="$REPO_ROOT/ansible"

SSH_KEY="$HOME/.ssh/id_rsa"


#################################
# Install dependencies
#################################

echo "🔍 Checking dependencies..."


# Git
if ! command -v git >/dev/null 2>&1; then
    echo "📦 Installing Git..."
    sudo dnf install git -y
else
    echo "✅ Git already installed"
fi


# Terraform
if ! command -v terraform >/dev/null 2>&1; then

    echo "📦 Installing Terraform..."

    sudo dnf install -y yum-utils

    sudo yum-config-manager \
    --add-repo \
    https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

    sudo dnf install terraform -y

else
    echo "✅ Terraform already installed"
fi



# Ansible
if ! command -v ansible >/dev/null 2>&1; then

    echo "📦 Installing Ansible..."

    sudo dnf install ansible -y

else
    echo "✅ Ansible already installed"
fi


echo "✅ All dependencies ready"

echo "🔑 Checking SSH key"

if [ ! -f "$SSH_KEY" ]; then

    ssh-keygen \
    -t rsa \
    -b 4096 \
    -C "ansible-key" \
    -N "" \
    -f "$SSH_KEY"

else
    echo "✅ SSH key already exists"
fi



echo "📌 Git configuration"

git config --global user.email "YOUR_EMAIL"
git config --global user.name "YOUR_USERNAME"

git remote -v



echo "🏗️ Terraform deployment"

cd "$TERRAFORM_DIR"

terraform init

terraform apply -auto-approve



echo "📡 Getting EC2 IP"

WEB_IP=$(terraform output -raw public_ip)

echo "EC2 IP: $WEB_IP"



echo "⚙️ Creating Ansible inventory"

cd "$ANSIBLE_DIR"

cat > inventory.ini <<EOF
[webservers]
web1 ansible_host=$WEB_IP ansible_user=ec2-user ansible_ssh_private_key_file=$SSH_KEY
EOF



echo "🤖 Running Ansible"

ansible-playbook \
-i inventory.ini \
playbook.yml


echo "📝 Checking Git changes"


cd "$REPO_ROOT"

if git diff --quiet && git diff --cached --quiet; then
    echo "ℹ️ No changes to commit."
else
    git add .

    git status

    git commit -m "Update project"

    echo

    read -p "Push to GitHub? (y/N): " PUSH_CHOICE

    if [[ "$PUSH_CHOICE" =~ ^[Yy]$ ]]; then
        echo "🚀 Pushing to GitHub..."
        git push -u origin main
        echo "✅ Changes pushed successfully."
    else
        echo "ℹ️ Push skipped. Changes are committed locally."
    fi
fi

echo "✅ Finished"
