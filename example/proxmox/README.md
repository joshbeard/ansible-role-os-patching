# Ansible Playbook for Patching Proxmox Guests

This is a shell script and Ansible playbook for patching Proxmox guests.

The `patch.sh` script is intended to be ran locally on a workstation or in
a CI/CD pipeline. It's a wrapper around the `ansible-playbook` command that
simplifies the commands and also provides retrieval of Proxmox credentials
from 1password using the `op` command.

## Contents

* [`patch.yml`](patch.yml): Ansible playbook for patching Proxmox guests.
* [`patch.sh`](patch.sh): Shell script for running the Ansible playbook.
* [`requirements.yml`](requirements.yml): Ansible requirements.
* [`ansible.cfg`](ansible.cfg): Ansible configuration file.
* [`example.proxmox.yml`](example.proxmox.yml): Example Proxmox inventory file.

## Usage

Run the `patch.sh` script without any arguments to see usage:

```shell
./patch.sh
```

To check for available updates, run with the `check` argument:

```shell
./patch.sh check
```

To apply updates, run with the `patch` argument:

```shell
./patch.sh patch
```

Hosts can also be pinged or their uptime checked:

```shell
./patch.sh ping
./patch.sh uptime
```

The `patch.sh` script also supports specifying target hosts or groups:

```shell
./patch.sh check proxmox_all_running
./patch.sh patch host1 host2
./patch.sh ping patch_group_A
```

Target hosts can also be specified using an environment variable:

```shell
export TARGET_HOSTS=host1,host2
./patch.sh patch

export TARGET_HOSTS=patch_group_A
./patch.sh ping
```
