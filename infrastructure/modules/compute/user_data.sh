#!/bin/bash
set -euxo pipefail

yum update -y
amazon-linux-extras enable nginx1
yum install -y nginx python3 awscli
systemctl enable nginx

# Allow Ansible to manage without requiring tty
echo 'Defaults:ec2-user !requiretty' >/etc/sudoers.d/90-ec2-user
chmod 440 /etc/sudoers.d/90-ec2-user

# Create placeholder index so ALB health checks succeed before Ansible runs
echo "<html><body><h1>Provisioning {{ environment }} stack</h1></body></html>" >/usr/share/nginx/html/index.html
systemctl restart nginx
