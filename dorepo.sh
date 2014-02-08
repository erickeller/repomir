#!/bin/bash
# create a repository server from scratch
# inspired from create_simbox.sh

SCRIPT_DIR=$(readlink -f ${0%/*})
REPO_ROOT_FS=${SCRIPT_DIR}/repomir

set -e
trap "on_exit" EXIT

usage()
{
  echo "
$0 usage:

examples:
$0
"
  exit 1
}
die()
{
  echo "the script did encounter some errors..."
  exit 1
}

repomir_configure()
{
  ${SCRIPT_DIR}/configure.sh
}

repomir_debootstrap()
{
  debootstrap precise ${REPO_ROOT_FS} http://de.archive.ubuntu.com/ubuntu/
  chroot ${REPO_ROOT_FS} locale-gen en_US.UTF-8
  . ${REPO_ROOT_FS}/etc/lsb-release
  echo -n repomir_rootfs > ${REPO_ROOT_FS}/etc/debian_chroot
  touch ${REPO_ROOT_FS}/etc/mtab
}

# only get the minimal source.list to start up with
# once git is setup, use etckeeper to get all the required configuration
#
repomir_apt()
{
  cat > ${REPO_ROOT_FS}/etc/apt/source.list << EOF
#############################################################
################### OFFICIAL UBUNTU REPOS ###################
#############################################################

###### Ubuntu Main Repos
deb http://ch.archive.ubuntu.com/ubuntu/ precise main restricted universe multiverse

###### Ubuntu Update Repos
deb http://ch.archive.ubuntu.com/ubuntu/ precise-security main restricted universe multiverse
deb http://ch.archive.ubuntu.com/ubuntu/ precise-updates main restricted universe multiverse
deb http://ch.archive.ubuntu.com/ubuntu/ precise-proposed main restricted universe multiverse
deb http://ch.archive.ubuntu.com/ubuntu/ precise-backports main restricted universe multiverse
EOF
}

repomir_mount_bind()
{
  mount --bind /dev ${REPO_ROOT_FS}/dev
  mount --bind /dev/pts ${REPO_ROOT_FS}/dev/pts
  mount --bind /proc ${REPO_ROOT_FS}/proc
  mount --bind /sys ${REPO_ROOT_FS}/sys
}

repomir_localtime()
{
  ln -sf /usr/share/zoneinfo/Europe/Zurich ${REPO_ROOT_FS}/etc/localtime
}

repomir_upgrade()
{
  chroot ${REPO_ROOT_FS} apt-get -y update || true
  chroot ${REPO_ROOT_FS} apt-get -y dist-upgrade
}

repomir_install_packages()
{
  export DEBIAN_FRONTEND=noninteractive
  chroot ${REPO_ROOT_FS} apt-get -y install ssh vim apache2 vsftpd acpid usbutils pciutils \
    syslinux ethtool tmux gawk zsh git-core
  # missing htop shorwall grub2
  chroot ${REPO_ROOT_FS} apt-get -y purge vim-tiny
  chroot ${REPO_ROOT_FS} apt-get clean
}

on_exit()
{
  grep -q ${REPO_ROOT_FS}/dev/pts       /proc/mounts && umount -l ${REPO_ROOT_FS}/dev/pts
  grep -q ${REPO_ROOT_FS}/dev           /proc/mounts && umount -l ${REPO_ROOT_FS}/dev
  grep -q ${REPO_ROOT_FS}/proc          /proc/mounts && umount -l ${REPO_ROOT_FS}/proc
  grep -q ${REPO_ROOT_FS}/sys           /proc/mounts && umount -l ${REPO_ROOT_FS}/sys
  grep -q ${REPO_ROOT_FS}/run/shm       /proc/mounts && umount -l ${REPO_ROOT_FS}/run/shm
}


# entry point
repomir_configure || die
#repomir_debootstrap || die
repomir_mount_bind || die
repomir_apt || die
repomir_localtime || die
repomir_upgrade || die
repomir_install_packages || die

exit 0
