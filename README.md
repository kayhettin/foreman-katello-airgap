# Air-Gapped Foreman & Katello Infrastructure Deployment

## Architecture & Objective Overview
This repository provides the GitOps automation and configuration necessary to deploy a disconnected host lifecycle management system utilizing Foreman 5.0 and Katello 5.0. The architecture bridges internet-connected domains (`STAGING_NODE`) with highly restricted, offline enclaves (`OFFLINE_ENCLAVE_A`, `OFFLINE_ENCLAVE_B`)

The `STAGING_NODE` synchronizes strictly filtered RPMs and DEBs via Katello's underlying Pulp engine, generating chunks that are sneakerneted across the air gap. The offline enclaves reconstruct these repositories locally, preserving full YUM, APT, Errata, and CVE auditing capabilities.

## Prerequisites
*   **Operating System:** Rocky Linux 9 Minimal.
*   **System Requirements:** Minimum 20GB RAM, 4 vCPUs, 512GB storage block. For a full mirror of both .deb and .rpms, 1TB is recommended.
*   **User Privileges:** All installation scripts strictly require a `root` user session. Do not prefix standard users with `sudo` during the core install phase, as `dnf` cache mappings will fail.

## Deployment Instructions

### Phase 1: STAGING_NODE (Internet-Connected Staging Node)
1.  Establish the underlying OS and clone this repository.
2.  Execute `scripts/01-deploy-staging-node.sh` to install the complete Katello ecosystem locally.
3.  Authenticate to the Katello Web UI (HTTPS over port 443) using the auto-generated credentials outputted in the terminal.
4.  Execute `scripts/02-configure-and-sync-upstream.sh` to establish the upstream Products, Repositories, and trigger synchronization.
5.  Generate the `content-export` via the Web UI or Hammer CLI and transfer the artifact to physical media (SE disk).

### Phase 2: OFFLINE_ENCLAVE_A / B (Disconnected Enclaves)
1.  Transfer the synchronization tarball to the offline Rocky 9 host.
2.  Execute `scripts/03-prepare-offline-node.sh` to extract the packages, disable default internet mirrors, and construct the local `file:///` DNF routing.
3.  Execute `scripts/04-install-offline-katello.sh` to build the internal application databases, systemd services, and routing rules based solely on local packages.
4.  Transfer the `content-export` tarball to the offline host.
5.  Execute `scripts/05-ingest-offline-content.sh` to populate PostgreSQL and Pulp with Errata metadata and physical artifacts.

## Directory/File Manifest
*   `configs/env.template`: Centralized variable declaration block for hostnames and filepaths.
*   `configs/offline-foreman.repo`: Critical DNF configuration file that maps required Katello installation components to local directories.
*   `scripts/01-deploy-staging-node.sh`: Bootstraps the connected node, applies baseline firewall rules, and installs Katello scenarios.
*   `scripts/02-configure-and-sync-upstream.sh`: Automates repository creation and sync initiation for core OS packages.
*   `scripts/03-prepare-offline-node.sh`: Isolates the disconnected server from network attempts and stages locally hosted binaries.
*   `scripts/04-install-offline-katello.sh`: Triggers the Katello backend orchestrator using the offline repository map.
*   `scripts/05-ingest-offline-content.sh`: Readies the Pulp engine permissions and fires the Hammer CLI import job.

## Validation & Smoke Testing
Run the following commands as an engineer to validate the deployment state:

1.  **Validate Service Integrity:**
    ```bash
    systemctl status pulpcore-api postgresql httpd
    ```
    *Expected output: All primary backend Katello services should report `active (running)`.*

2.  **Validate Port State:**
    ```bash
    sudo firewall-cmd --list-ports
    ```
    *Expected output: `80/tcp 443/tcp 8140/tcp` must be present.*

3.  **Validate Repository Population (Offline):**
    ```bash
    hammer product list
    ```
    *Expected output: "Rocky Linux 9" (or corresponding Ubuntu products) should be visible and populated after the `content-import` script executes.*

## Troubleshooting / Common Pitfalls

*   **Libvirt Permissions on Ubuntu Hosts:** If hosting the staging VM on an Ubuntu desktop via KVM/virt-manager, a `Permission denied` error on `libvirt-sock` indicates standard user IDs have not loaded group assignments. Execute `newgrp libvirt` in the terminal to bypass this without needing `sudo`.
*   **RPM Installation Hangs/Failures:** If `dnf` errors with `Could not resolve host: mirrors.rockylinux.org`, the default OS repos are overriding the offline map. Ensure all `.repo` files in `/etc/yum.repos.d/` excluding `offline-foreman.repo` are moved to a backup directory, and execute `dnf clean all`.
*   **rocky-release GPG Check Failures:** The offline installer will halt if it attempts to validate or update the standard `rocky-release` package. Ensure the `exclude=rocky-release*` flag remains in the `[offline-baseos]` block of the repository map.
*   **Cache Execution Errors (`[Errno 2]`):** If `dnf` outputs `cannot set cachedir` indicating `/var/tmp/dnf-...`, you are executing as a standard user with `sudo` rather than a dedicated root session. Run `sudo su` and retry.
