#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
if ! test -f $(basename $0);then echo "  EE run this script in its folder";exit;fi
cd archives
trap "rm -f ../tmp/server.dat.tmp; trap - EXIT; exit" EXIT INT HUP TERM QUIT
. ../update-provider.inc.sh

__UPDATE_DATE(){
  if echo "$1" | ag --no-color '^[0-9A-Za-z_]{1,12}-[0-9A-Za-z]{34}\.itp\.tar\.gz$' > /dev/null;then
    BUF=$(tar -tvf "$1" --utc | ag '[0-9A-Za-z_]{1,12}-[0-9A-Za-z]{34}\.itp\.sha512sum$' | head -n 1 | awk '{print $4" "$5}')
  elif echo "$1" | ag --no-color "^$UPD_NAME_REGEXP$" > /dev/null;then
    BUF=$(tar -tvf "$1" --utc | ag '/Goldkarpfen\.sh' | head -n 1 | awk '{print $4" "$5}')
  else
    return
  fi
  if test -z "$BUF";then
    >&2 echo "  EE $1 doas not contain an itp file - moved to quarantine"
    mv $1 ../quarantine/"$1.$(mktemp -u XXXXXXXX)"
    return
  fi
  DATE=$(date --utc -d "$BUF" +"%y-%m-%d")
  echo "$1 $DATE"
}

if test -z "$1";then
  echo -n "" > ../tmp/server.dat.tmp
  for FILE in *.tar.gz;do
    __UPDATE_DATE "$FILE" >> ../tmp/server.dat.tmp
  done
  if ! cmp ../tmp/server.dat.tmp ../archives/server.dat > /dev/null 2>&1;then mv ../tmp/server.dat.tmp ../archives/server.dat;fi
else
  touch -a ./server.dat
  sed -i "/$1/d" ./server.dat
  if test -f "$1";then __UPDATE_DATE "$1" >> ./server.dat;fi
fi
