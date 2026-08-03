#!/bin/bash

set -e

echo "🚀 Starting DevSpace deployment"

REPO_ROOT=$(pwd)

TERRAFORM_DIR="$REPO_ROOT/terraform"
ANSIBLE_DIR="$REPO_ROOT/ansible"

SSH_KEY="$HOME/.ssh/id_rsa"


echo "🔍 Checking dependencies"

for cmd in terraform ansible git; do
    if ! command -v $cmd >/dev/null 2>&1; then
        echo "❌ $cmd is missing"
        exit 1
    fi
done


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

WEB_IP=$(terraform output -raw web_public_ip)

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



echo "📝 Git commit"

cd "$REPO_ROOT"

git add .

git status


read -p "Commit message: " MESSAGE

git commit -m "$MESSAGE"


echo "🚀 Push to GitHub"

git push -u origin main


echo "✅ Finished"
