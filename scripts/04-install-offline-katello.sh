#!/usr/bin/env bash
set -euo pipefail

echo "Installing Katello locally..."
# Install using the newly mapped local file:/// offline repos
dnf install -y foreman-installer-katello

echo "Executing Foreman Installer..."
foreman-installer --scenario katello

echo "Configuring Firewall..."
firewall-cmd --add-port={80/tcp,443/tcp,8140/tcp} --permanent
firewall-cmd --reload
