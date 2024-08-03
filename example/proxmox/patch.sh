#!/usr/bin/env bash
# Proxmox OS Patching Script
#
# This script automates the process of patching and rebooting hosts in a
# Proxmox environment using Ansible. It dynamically sets the target hosts,
# retrieves Proxmox credentials from 1Password, and runs Ansible playbooks to
# check or apply patches.
#
# It's intended to be ran on a local machine with Ansible and 1Password CLI
# installed and configured to interact with the Proxmox environment.
#
# The script performs the following tasks:
# 1. Checks for the presence of necessary commands (ansible-playbook, op, jq).
# 2. Retrieves Proxmox credentials from 1Password and sets them as environment
#    variables.
# 3. Dynamically sets the target hosts based on provided arguments or defaults
#    to 'proxmox_all_running'.
# 4. Runs the appropriate Ansible playbook tags (check or patch) on the
#    specified target hosts.
#
# Usage:
#   The script can be run with 'check' or 'patch' commands followed by optional
#   target hosts. If no target hosts are specified, it defaults to
#   'proxmox_all_running'.
#
# Examples:
#   ./script.sh check                 # Check all running hosts in Proxmox
#   ./script.sh check host1           # Check a single host
#   ./script.sh check host1 host2     # Check multiple hosts
#   ./script.sh patch                 # Patch all running hosts in Proxmox
#   ./script.sh patch host1           # Patch a single host
#
# Environment Variables (optional):
#   ANSIBLE_USER       - The Ansible user to run the playbooks (default: current user)
#   ANSIBLE_PLAYBOOK   - The Ansible playbook to run (default: patch.yml)
#   TARGET_HOSTS       - The target hosts for the playbook (default: proxmox_all_running)
#
# Dependencies:
#   - Ansible
#   - 1Password CLI (op)
#   - jq
#   - Ansible Community Collection (community.general)

# Default values
ANSIBLE_USER=${ANSIBLE_USER:-$(whoami)}
ANSIBLE_PLAYBOOK=${ANSIBLE_PLAYBOOK:-patch.yml}
TARGET_HOSTS=${TARGET_HOSTS:-proxmox_all_running}

USE_1PASSWORD=${USE_1PASSWORD:-true}
OP_SECRET_NAME=${OP_SECRET_NAME:-Homelab Secrets}
OP_FIELD_USERNAME=${OP_FIELD_USERNAME:-proxmox_username}
OP_FIELD_PASSWORD=${OP_FIELD_PASSWORD:-proxmox_password}
OP_FIELD_URL=${OP_FIELD_URL:-proxmox_url}

# Function to display usage information
usage() {
  echo "Usage: $0 <command> [target_hosts]"
  echo
  echo "Commands:"
  echo "  check   - Check for available patches"
  echo "  patch   - Apply patches and reboot if necessary"
  echo "  ping    - Ping the target hosts"
  echo "  uptime  - Check the uptime of the target hosts"
  echo
  echo "Examples:"
  echo "  Running against all running hosts in Proxmox:"
  echo "    $0 check"
  echo
  echo "  Running against a single host:"
  echo "    $0 check host1"
  echo "    TARGET_HOSTS=host1 $0 check"
  echo
  echo "  Running against multiple hosts:"
  echo "    $0 check host1 host2"
  echo "    $0 check host1,host2"
  echo "    TARGET_HOSTS=host1,host2 $0 check"
  echo
  echo "  Running against a host group:"
  echo "    $0 check patch1"
  echo "    TARGET_HOSTS=patch1 $0 check"
  echo
  exit 1
}

# Function to check prerequisites
check_prerequisites() {
  if ! command -v ansible-playbook &> /dev/null; then
    echo "ansible-playbook could not be found. Please install Ansible."
    exit 1
  fi

  if ! command -v op &> /dev/null; then
    echo "1Password CLI (op) could not be found. Please install 1Password CLI."
    exit 1
  fi

  if ! command -v jq &> /dev/null; then
    echo "jq could not be found. Please install jq."
    exit 1
  fi
}

# Function to set Proxmox credentials from 1Password
set_proxmox_credentials() {
  # Retrieve the Proxmox secrets from 1Password
  local proxmox_secrets
  proxmox_secrets=$(op item get "${OP_SECRET_NAME}" --format json | jq -r '.fields[] | {label, value} | @base64')

  # Decode and set environment variables
  for secret in ${proxmox_secrets}; do
    # Decode each secret
    local decoded_secret
    decoded_secret=$(echo "${secret}" | base64 --decode)

    # Extract the label and value
    local label
    local value
    label=$(echo "${decoded_secret}" | jq -r '.label')
    value=$(echo "${decoded_secret}" | jq -r '.value')

    # Set environment variables based on the label
    case "${label}" in
      "${OP_FIELD_USERNAME}")
        export PROXMOX_USER="${value}"
        ;;
      "${OP_FIELD_PASSWORD}")
        export PROXMOX_PASSWORD="${value}"
        ;;
      "${OP_FIELD_URL}")
        export PROXMOX_URL="${value}"
        ;;
      *)
        ;;
    esac
  done

  # Check if all required environment variables are set
  if [ -z "${PROXMOX_USER}" ] || [ -z "${PROXMOX_PASSWORD}" ] || [ -z "${PROXMOX_URL}" ]; then
    echo "Failed to set all required Proxmox credentials. Please check your 1Password item."
    return 1
  fi

  echo "Proxmox credentials have been set successfully."
}

# Helper function to run ansible-playbook
run_ansible_playbook() {
  local tags=$1
  ansible-playbook -u "${ANSIBLE_USER}" \
    -e "target_hosts=${TARGET_HOSTS}" \
    --tags "${tags}" \
    "${ANSIBLE_PLAYBOOK}"
}

get_from_1password() {
  local item=$1
  local field=$2
  op get item "${item}" | jq -r ".details.fields[] | select(.designation == \"${field}\") | .value"
}

# Function to run check
check() {
  run_ansible_playbook "check"
}

# Function to run patch
patch() {
  run_ansible_playbook "patch,reboot"
}

ansible_ping() {
  ansible -m ping -u "${ANSIBLE_USER}" "${TARGET_HOSTS}"
}

check_uptime() {
  ansible -m command -a "uptime" -u "${ANSIBLE_USER}" "${TARGET_HOSTS}"
}

# Check for prerequisites
check_prerequisites

if [ "${USE_1PASSWORD}" == "true" ]; then
  # Set Proxmox credentials from 1Password
  set_proxmox_credentials
fi

# Treat extra args as target hosts, join them with commas
if [ $# -gt 1 ]; then
  TARGET_HOSTS=$(IFS=,; echo "${*:2}")
fi

# Main case statement to handle user commands
case "$1" in
  check)
    check
    ;;
  patch)
    patch
    ;;
  ping)
    ansible_ping
    ;;
  uptime)
    check_uptime
    ;;
  *)
    usage
    ;;
esac

