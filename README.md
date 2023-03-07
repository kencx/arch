# arch

Ansible playbook for automating the installation and configuration of an
Arch Linux workstation/laptop.

The playbook should be run locally after a fresh install or remotely, if
networking and SSH has already been setup. Ensure that all variables have been
appropriately set before running the playbook. You may also choose to skip
certain tasks/roles via the use of tags.

## Prerequisites
Run `prepare.sh` to install a base Arch Linux system on a chosen disk. It requires the
following dependencies:

```
sgdisk mkfs.fat mkfs.btrfs pacstrap pacman genfstab arch-chroot btrfs
```

On an existing Arch system, they can be installed with:

```bash
$ pacman -S gdisk dosfstools arch-install-scripts btrfs-progs
$ sudo ./prepare.sh
```

The script:
- Formats and partitions a chosen disk into a boot and root partition.
- Creates btrfs subvolumes within the root partition and mounts them at the chosen mount
  point.
- Installs the base Arch system in the chosen mount point.
- chroot into the new base system and runs `./post-install.sh`.

## Running the playbook

Running locally:

```bash
$ ansible-playbook -i inventory --limit local main.yml
```

Running remotely:

```bash
# add remote machine to inventory
$ cat <<EOF >> inventory
[workstation]
10.10.10.100 ansible_user=username
EOF

$ ansible-playbook -i inventory --limit workstation main.yml
```

Running on non-laptop host:

```bash
$ ansible-playbook main.yml --skip-tags="laptop"
```

Base configuration (only base, networking and security):

```bash
$ ansible-playbook main.yml --tags="untagged"
```

See [ROLES](ROLES.md) for all tags or use `list-tags`:

```bash
$ ansible-playbook main.yml --list-tags
```

## References
- [spark](https://github.com/pigmonkey/spark/)
