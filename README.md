# Ansible OS Patching Role

An Ansible role for OS patching.

This is a basic role for use on my personal homelab servers, so OS support is
limited.

## OS Support

* Debian/Ubuntu: Uses `apt`
* EL: Uses `dnf`
* FreeBSD: Uses `pkg-ng`

## Usage

### Tags

- `check`: Check for available updates without installing them.
- `reboot`: Reboot the system after patching if necessary.

When no tags are specified, the system will be patched without rebooting.

### Variables

- `patching_reboot_ok`: If `true`, the system will be rebooted if necessary
  after patching. Default is `false`.

### Example Playbook

```yaml
- name: "OS Patching"
  hosts: proxmox_all_running
  gather_facts: true
  become: true
  vars:
    patching_reboot_ok: true
  roles:
    - jbeard-os_patching
```

See [example/proxmox](example/proxmox) for a full playbook example that
uses the [`community.general.proxmox`](https://docs.ansible.com/ansible/latest/collections/community/general/proxmox_inventory.html)
inventory source.

The [`example/proxmox/patch.sh`](example/proxmox/patch.sh) script can be used
generically and makes running the playbook easier, including support for
retrieving credentials from 1Password.

### Rebooting

If the `patching_reboot_ok` variable is set to `true` and the `reboot` tag is
set, the system will be rebooted if the system requires a reboot after
patching.
