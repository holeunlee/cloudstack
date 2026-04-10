# cloudstack

Bash scripts to deploy a self-hosted [Apache CloudStack](https://cloudstack.apache.org/) environment on Ubuntu, designed to run unattended via cloud-init.

## Scripts

| Script | Purpose |
|---|---|
| `00-cloudstack-allinone.sh` | All-in-one install (management + KVM host on a single node) |
| `00-cloudstack-allinone-cloudmonkey.sh` | Same as above, also installs CloudMonkey CLI |
| `01-cloudstack-database.sh` | Database node setup (MySQL) |
| `02-cloudstack-storage.sh` | NFS primary/secondary storage setup |
| `03-cloudstack-management.sh` | Management server setup |
| `04-cloudstack-kvmhost.sh` | KVM hypervisor host setup |

## Usage

Run as root on the target node:

```bash
bash 00-cloudstack-allinone.sh
```

For a multi-node setup, run the numbered scripts in order on their respective nodes.

## Notes

- Based on the official CloudStack documentation
- Tested on Ubuntu 22.04 / 24.04
- Designed to work as cloud-init boot scripts — no Ansible or external dependencies required
