#!/bin/bash
# create a repository server from scratch
# inspired from create_simbox.sh

SCRIPT_DIR=$(readlink -f ${0%/*})
REPO_ROOT_FS=${SCRIPT_DIR}/repomir_fs
REPO_CODENAME=precise
REPO_URL=http://ch.archive.ubuntu.com/ubuntu/
# using a local mirror repository
REPO_URL=file:///media/mariole/repo/
LOCAL_REPO_MOUNT=`sed -e "s#file://##g" <<< "file:///media/mariole/repo/"`

# debmir git projet url
DEBMIR_URL=https://github.com/erickeller/debmir.git
# etckeeper git project url
ETCKEEPER_URL=https://github.com/erickeller/etckeeper-repomir.git

FAKE=fakeroot
FAKECH=fakechroot

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

repomir_configure_script()
{
  ${SCRIPT_DIR}/configure.sh
}

repomir_debootstrap()
{
  echo "debootstrap..."
  debootstrap ${REPO_CODENAME} ${REPO_ROOT_FS} ${REPO_URL}
  chroot ${REPO_ROOT_FS} locale-gen en_US.UTF-8
  . ${REPO_ROOT_FS}/etc/lsb-release
  echo -n repomir_rootfs > ${REPO_ROOT_FS}/etc/debian_chroot
  touch ${REPO_ROOT_FS}/etc/mtab
}

# only get the minimal source.list to start up with
# once git is setup, use etckeeper to get all the required configuration
#
repomir_configure_sources_list()
{
  echo "confiure sources.list..."
  cat > ${REPO_ROOT_FS}/etc/apt/sources.list << EOF
#############################################################
################### OFFICIAL UBUNTU REPOS ###################
#############################################################

###### Ubuntu Main Repos
deb ${REPO_URL} precise main restricted universe multiverse

###### Ubuntu Update Repos
deb ${REPO_URL} precise-security main restricted universe multiverse
deb ${REPO_URL} precise-updates main restricted universe multiverse
deb ${REPO_URL} precise-backports main restricted universe multiverse
EOF
}

pre_install_configure()
{
  cat > ${REPO_ROOT_FS}/usr/local/bin/invoke-rc.d <<EOF
echo PREVENTING /usr/local/bin/invoke-rc.d \$@
EOF
  chmod +x ${REPO_ROOT_FS}/usr/local/bin/invoke-rc.d
}

repomir_mount_bind()
{
  mount --bind /dev ${REPO_ROOT_FS}/dev
  mount --bind /dev/pts ${REPO_ROOT_FS}/dev/pts
  mount --bind /proc ${REPO_ROOT_FS}/proc
  mount --bind /sys ${REPO_ROOT_FS}/sys
  # only create local
  if [[ "${REPO_URL}" =~ "file:" ]]
  then
    echo "binding local repo: ${LOCAL_REPO_MOUNT} to the chroot fs"
    chroot ${REPO_ROOT_FS} mkdir -p ${LOCAL_REPO_MOUNT}
    mount --bind ${LOCAL_REPO_MOUNT} ${REPO_ROOT_FS}${LOCAL_REPO_MOUNT}
  fi
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
  chroot ${REPO_ROOT_FS} apt-get -y install ssh vim apache2 vsftpd acpid usbutils xfsprogs pciutils \
    info man htop shorewall grub2 syslinux ethtool tmux gawk zsh git-core git-svn etckeeper ack-grep debmirror
  chroot ${REPO_ROOT_FS} apt-get -y purge vim-tiny
  chroot ${REPO_ROOT_FS} apt-get autoclean
}

# after package installation, need some configurations
post_install_configure()
{
  # setup git for etckeeper remove shadow files
  chroot ${REPO_ROOT_FS} /bin/bash -x << EOF
sed -i 's/VCS="bzr"/#VCS="bzr"/g;s/#VCS="git"/VCS="git"/g' /etc/etckeeper/etckeeper.conf
etckeeper init
pushd /etc
git rm --cached shadow* group* passwd*
echo "
# discard shadow passwd group
passwd*
group*
shadow*
" >> /etc/.gitignore
echo "
[user]
  name = repomir scatch
  email = root@repomir
" >> /etc/.git/config
git remote add origin ${ETCKEEPER_URL}
popd
etckeeper commit -m "initial commit"
EOF
}

on_exit()
{
  echo "exiting, umount, cleanup..."
  grep -q ${REPO_ROOT_FS}/dev/pts       /proc/mounts && umount -l ${REPO_ROOT_FS}/dev/pts
  grep -q ${REPO_ROOT_FS}/dev           /proc/mounts && umount -l ${REPO_ROOT_FS}/dev
  grep -q ${REPO_ROOT_FS}/proc          /proc/mounts && umount -l ${REPO_ROOT_FS}/proc
  grep -q ${REPO_ROOT_FS}/sys           /proc/mounts && umount -l ${REPO_ROOT_FS}/sys
  grep -q ${REPO_ROOT_FS}/run/shm       /proc/mounts && umount -l ${REPO_ROOT_FS}/run/shm

  if [[ "${REPO_URL}" =~ "file:" ]]
  then
    umount -l ${REPO_ROOT_FS}/media/mariole/repo
  fi
  chroot ${REPO_ROOT_FS} umount -a
}


# entry point
repomir_configure_script || die
repomir_debootstrap || die
repomir_mount_bind || die
repomir_configure_sources_list || die
repomir_localtime || die
repomir_upgrade || die
repomir_install_packages || die
on_exit
exit 0
