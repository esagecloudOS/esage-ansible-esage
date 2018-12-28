# Ansible Role: Abiquo

Installs and configures several [Abiquo Hybrid Cloud](https://www.abiquo.com) platform components.

## Dependencies

This role includes [geerlingguy.firewall](https://galaxy.ansible.com/geerlingguy/firewall/) for iptables configuration. You can use the following command to install all dependencies:

```
$ ansible-galaxy install -r requirements.yml
```

## Role Variables

Some of the available variables are listed below, along with default values. For a complete list of variables, see `defaults/main.yml`.

```
abiquo_profile: monolithic
```

This variable sets the profile of the server in an Abiquo environment. Possible values are:

- `frontend`: Just UI server.
- `server`: API and M module (UI optional through use of `abiquo_install_frontend` variable).
- `remoteservices`: RS services.
- `v2v`: The V2V converter component.
- `monitoring`: Watchtower monitoring components.
- `kvm`: A KVM hypervisor along the AIM agent.
- `monolithic`: Server with frontend, RS and V2V in one server.

## Example Playbook

```
- hosts: server
  vars:
    abiquo_profile: monolithic
  roles:
    - { role: abiquo }
```

# License and Authors

* Author:: Marc Cirauqui (marc.cirauqui@abiquo.com)

Copyright:: 2018, Abiquo

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
