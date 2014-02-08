#!/bin/bash
# create a repository server from scratch
# inspired from create_simbox.sh

SCRIPT_DIR=$(readlink -f ${0%/*})
REPO_ROOT_FS=repomir


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

configure()
{
  ${SCRIPT_DIR}/configure.sh
}

configure || die

exit 0
