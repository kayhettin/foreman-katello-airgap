#!/usr/bin/env bash
set -euo pipefail
source ../configs/env.template

# Requires hammer content-export tarball transferred to /tmp/katello-content-export.tar
EXPORT_TAR="/tmp/katello-content-export.tar"

echo "Extracting Katello Content Export..."
mkdir -p "${PULP_IMPORT_DIR}"
tar -xvf "${EXPORT_TAR}" -C "${PULP_IMPORT_DIR}/"

echo "Applying Pulp User Permissions..."
chown -R pulp:pulp "${PULP_IMPORT_DIR}/"

echo "Executing Hammer Import..."
# Note: Directory path will dynamically change based on export timestamp, using wildcard match for latest
IMPORT_TARGET=$(find "${PULP_IMPORT_DIR}" -maxdepth 1 -type d -name "Default_Organization*" | head -n 1)

hammer content-import library \
  --organization="${ORG_NAME}" \
  --path="${IMPORT_TARGET}"
