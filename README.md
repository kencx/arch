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

Pick and choose:

```bash
$ ansible-playbook main.yml --tags="untagged,dev" --skip-tags="qemu"
```

See [ROLES](ROLES.md) for all tags or use `list-tags`:

```bash
$ ansible-playbook main.yml --list-tags
```

## Installing Packages from AUR

All AUR packages are installed via a custom repository and will be tagged with
the `aur` tag. This requires a local or remote custom repository with added AUR
packages. It must be included as an additional server in the `aur` role:

```yml
# set to $USER
aur_user: arch
aur_custom_repo_name: "custom"
aur_custom_repo_dir: "/var/cache/pacman/{{ aur_custom_repo_name }}"
aur_custom_repo_sig_level: "Optional TrustAll"

# local repo
aur_custom_repo_url: "file://{{ aur_custom_repo_dir }}"

# remote repo
aur_custom_repo_url: "https://aur.example.xyz/aur"
```

along with tag `aur` when running the playbook:

```bash
$ ansible-playbook main.yml --tags="aur"
```

### Remote Repository

A remote repository can be hosted on any remote file server or S3 bucket. The
custom `aura` script assumes the custom repository is located in an Minio S3 bucket.

## References
- [spark](https://github.com/pigmonkey/spark/)
