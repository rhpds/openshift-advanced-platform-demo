# OpenShift Advanced Platform Automation Collection

This Ansible collection provides automation for deploying and configuring the OpenShift Advanced Platform Demo.

## Collection: ocp_advanced_platform.automation

### Roles

- **ocp4_etx_app_platform**: Deploy and configure the OpenShift Advanced Application Platform demo environment

### Installation

```bash
ansible-galaxy collection install ocp_advanced_platform.automation
```

### Usage

```yaml
---
- name: Deploy OpenShift Advanced Platform Demo
  hosts: localhost
  tasks:
    - name: Deploy ETX App Platform
      ansible.builtin.include_role:
        name: ocp_advanced_platform.automation.ocp4_etx_app_platform
```

## Maintainer

Markus Nagel <mnagel@redhat.com>

## Repository

Source code: https://github.com/rhpds/openshift-advanced-platform-demo

## License

GPL-2.0-or-later
