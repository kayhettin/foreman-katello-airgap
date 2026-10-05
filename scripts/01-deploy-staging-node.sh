#!/usr/bin/env bash
set -euo pipefail
source ../configs/env.template

echo "Configuring Hostname..."
hostnamectl set-hostname "${STAGING_FQDN}"[cite: 11]
# Idempotent host file update
if ! grep -q "${STAGING_FQDN}" /etc/hosts; then
    echo "$(hostname -I | awk '{print $1}') $(hostname -f) $(hostname -s)" >> /etc/hosts[cite: 11]
fi

echo "Installing Release Repositories..."
dnf install -y https://yum.theforeman.org/releases/5.0/el9/x86_64/foreman-release.rpm \
               https://yum.theforeman.org/katello/5.0/katello/el9/x86_64/katello-repos-latest.rpm \
               https://yum.puppet.com/puppet8-release-el-9.noarch.rpm[cite: 11, 14]
dnf install -y epel-release[cite: 11]

echo "Installing Katello Scenario..."
dnf install -y foreman-installer-katello[cite: 14]

echo "Executing Foreman Installer..."
foreman-installer --scenario katello[cite: 14]

echo "Configuring Firewall..."
firewall-cmd --add-port={80/tcp,443/tcp,8140/tcp} --permanent
firewall-cmd --reload[cite: 27]
