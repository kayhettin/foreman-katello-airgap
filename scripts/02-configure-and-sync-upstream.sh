#!/usr/bin/env bash
set -euo pipefail
source ../configs/env.template

# Example of automating product/repo creation via Hammer CLI for Rocky 9
hammer product create --name "Rocky Linux 9" --organization "${ORG_NAME}"[cite: 9]

# Create BaseOS Repo[cite: 9, 17]
hammer repository create \
  --name "BaseOS" \
  --product "Rocky Linux 9" \
  --organization "${ORG_NAME}" \
  --content-type "yum" \
  --url "https://dl.rockylinux.org/pub/rocky/9/BaseOS/x86_64/os/"

# Trigger Synchronization[cite: 10, 18]
hammer repository synchronize --name "BaseOS" --product "Rocky Linux 9" --organization "${ORG_NAME}"
