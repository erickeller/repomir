#!/bin/sh

# check if your system has all the required software installed
# like: debootstrap, wget, ...

return_value=0
# add additional programm here
LISTING="debootstrap wget gpg pbzip2 fakeroot fakechroot"
MISSING_LIST=""

# take a listing and check if the porgramm exists
checker()
{
  for prog in ${LISTING}
  do
    if which ${prog} >/dev/null; then
      echo "${prog}\t\tOK"
    else
      echo "${prog}\t\tmissing!!!"
      MISSING_LIST="${MISSING_LIST} ${prog}"
      return_value=1
  fi
  done
}
checker
if [ "" != "${MISSING_LIST}" ]
then
  echo "install missing software
apt-get update && apt-get install ${MISSING_LIST}"
fi
exit ${return_value}
