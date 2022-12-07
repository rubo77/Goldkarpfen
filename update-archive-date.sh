#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
if ! test -f $(basename "$0");then echo "  EE run this script in its folder";exit 1;fi
cd archives && touch -a ./server.dat && . ../update-provider.inc.sh || exit 1
trap "rm -f ../tmp/server.dat.tmp; trap - EXIT; exit 0" INT HUP TERM QUIT
trap "rm -f ../tmp/server.dat.tmp; trap - EXIT; exit" EXIT
__UPDATE_DATE(){
  if echo "$1" | ag --no-color "^[0-9A-Za-z_]{1,12}-[0-9A-Za-z]{34}\.itp\.tar\.gz$|^$UPD_NAME_REGEXP$" > /dev/null;then
    BUF=$(date --utc "+%y-%m-%d" -d $(tar -tvf "$1" --utc | head -n 1 | awk '{print $4}'))
  else
    return 0
  fi
  if test -z "$BUF";then
    >&2 echo "  EE $1 does not contain an itp file - moved to quarantine"
    mv "$1" "$(mktemp -p ../quarantine "GARBAGE_$1.XXXXXXXX")" || exit 1
    return 0
  fi
  DATE=$(date --utc +"%y-%m-%d" -d $BUF)
  DDATE="$(ls "$1"* | tail -n 1 | ag -o "D\d\d-\d\d-\d\d$")"
  if test -z "$DDATE";then echo "$1 $DATE";else echo "$1 $DATE $DDATE";fi
  return 0
}

if test -z "$1";then
  echo -n "" > ../tmp/server.dat.tmp || exit 1
  for FILE in *.tar.gz;do
    __UPDATE_DATE "$FILE" >> ../tmp/server.dat.tmp || exit 1
  done
  if ! cmp ../tmp/server.dat.tmp ../archives/server.dat > /dev/null 2>&1;then mv ../tmp/server.dat.tmp ../archives/server.dat || exit 1;fi
else
  sed -i "/^$1/d" ./server.dat || exit 1
  if test -f "$1";then __UPDATE_DATE "$1" >> ./server.dat || exit 1;fi
fi
