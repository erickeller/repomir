repomir
=======

generate a repository mirror server from scratch

preprequisite:

In order to start this script you need sudo permission.
The configure.sh script is called from the dorepo.sh script and check if the required program are installed on your system.
If there are missing packages, please follow the instructions given by the configure.sh script

Usage:

Before starting to create your repo mirror server, please take a moment to edit the following global variable in the dorepo.sh script

REPO_CODENAME=precise, or whatever you need
REPO_URL=http://ch.archive.ubuntu.com/ubuntu/, choose a location near to you.

Note: 
if you have already a repo mirror on a local drive define it like the following:
REPO_URL=file:///media/mariole/repo/
otherwise delete this second REPO_URL definition.

DEBMIR_URL=https://github.com/erickeller/debmir.git, point to a debmirror helper scripts, especially getting keys and stuff, will also be used to rsync the mirror.

ETCKEEPER_URL=https://github.com/erickeller/etckeeper-repomir.git, or point to your own remote git repo...

after editing these variable to your needs, call the script:

chmod +x ./dorepo.sh
sudo ./dorepo.sh

Happy mirroring.

