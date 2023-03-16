#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
if ! test -f $(basename "$0");then echo "  EE run this script in its folder";exit 1;fi
cd archives || exit 1
if test "$(stat *.tar.gz* server.dat 2>/dev/null | sha256sum)" = "$(cat ../cache/archives.sha512sum 2> /dev/null)";then exit 0;fi
touch -a ./server.dat && . ../update-provider.inc.sh || exit 1
if ! test -z "$LISTING_REGEXP";then UPD_NAME_REGEXP=$LISTING_REGEXP;fi
__UPDATE_DATE(){
  if echo "$1" | ag --no-color "^[0-9A-Za-z_]{1,12}-[0-9A-Za-z]{34}\.itp\.tar\.gz$|^$UPD_NAME_REGEXP$" > /dev/null;then
    BUF=$(TZ=UTC tar -tvf "$1" | head -n 1 | awk '{print $4}' | ag -o "\d\d-\d\d-\d\d")
  else
    return 0
  fi
  if test -z "$BUF";then
    >&2 echo "  EE $1 does not contain an itp file - moved to quarantine"
    mv "$1" "$(mktemp -p ../quarantine "GARBAGE_$1.XXXXXXXX")" || exit 1
    return 0
  fi
  DATE=$BUF
  DDATE="$(ls "$1"* | tail -n 1 | ag -o "D\d\d-\d\d-\d\d$")"
  if test -z "$DDATE";then echo "$1 $DATE";else echo "$1 $DATE $DDATE";fi
  return 0
}

if test -z "$1";then
  for FILE in *.tar.gz;do
    T_BUF="$(__UPDATE_DATE "$FILE")"
    if ! test -z "$T_BUF";then SERVER_DAT="$SERVER_DAT$T_BUF\n";fi
  done
  if ! test "$SERVER_DAT" = "$(tr '\n' '\\' < ../archives/server.dat | sed 's/%/%%/g' | sed 's/\\/\\n/g')";then printf "$SERVER_DAT" > ../archives/server.dat || exit 1;fi
else
  sed -i "/^$1/d" ./server.dat || exit 1
  if test -f "$1";then __UPDATE_DATE "$1" >> ./server.dat || exit 1;fi
fi
stat *.tar.gz* server.dat 2>/dev/null | sha256sum > ../cache/archives.sha512sum || exit 1
