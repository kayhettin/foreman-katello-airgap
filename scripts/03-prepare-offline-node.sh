#!/usr/bin/env bash
set -euo pipefail
source ../configs/env.template

# Requires sneakernet tarball transferred to /tmp/foreman-katello-repos.tar.gz
TAR_SOURCE="/tmp/foreman-katello-repos.tar.gz"

echo "Extracting Offline Repositories..."
mkdir -p "${OFFLINE_REPO_DIR}"
if command -v tar >/dev/null 2>&1; then
    tar -xvf "${TAR_SOURCE}" -C "${OFFLINE_REPO_DIR}/"
else
    # Fallback if standard OS tar is not present on minimal ISO
    python3 -c "import tarfile; tarfile.open('${TAR_SOURCE}').extractall('${OFFLINE_REPO_DIR}/')"
fi

echo "Isolating Default Repositories..."
mkdir -p /etc/yum.repos.d/backup
# Move default repos to prevent network timeouts and curl resolution errors
find /etc/yum.repos.d/ -maxdepth 1 -name "*.repo" -exec mv {} /etc/yum.repos.d/backup/ \;

echo "Applying Local Repository Map..."
cp ../configs/offline-foreman.repo /etc/yum.repos.d/
dnf clean all
dnf repolist
