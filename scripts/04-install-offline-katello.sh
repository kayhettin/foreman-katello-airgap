#!/usr/bin/env bash
set -euo pipefail

echo "Installing Katello locally..."
# Install using the newly mapped local file:/// offline repos
dnf install -y foreman-installer-katello

echo "Executing Foreman Installer..."
foreman-installer --scenario katello[cite: 22, 23]

echo "Configuring Firewall..."
firewall-cmd --add-port={80/tcp,443/tcp,8140/tcp} --permanent[cite: 27]
firewall-cmd --reload[cite: 27]
