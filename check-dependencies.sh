#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
set -- "ag awk basename cat cmp cp cut date dc dd diff du file fold grep gunzip gzip head ls mkdir mktemp mv openssl pgrep printf ps sed seq sha512sum sort stat tail tar touch tput tr uniq wc xxd"
__WHICH(){
  for PROG in $1;do
    if ! command -v "$PROG" > /dev/null;then echo >&2 "  EE $PROG not found";return 1;fi
  done
}
RE=
if test -z $EDITOR;then echo >&2 "EDITOR env var is empty.";echo "ERROR";exit 1;fi
if ! command -v fzy > /dev/null && ! command -v fzf > /dev/null;then >&2 echo "  EE fzf or fzy not found";echo "ERROR";exit 1;fi
if ! __WHICH "$1";then echo "ERROR";exit 1;else RE="ok";fi
if __WHICH "curl";then RE="get $RE";fi
if __WHICH "darkhttpd";then RE="host $RE";fi
if pgrep i2pd > /dev/null 2>&1;then RE="i2p $RE";fi
if pgrep tor > /dev/null 2>&1;then RE="tor-static $RE";fi
if python3 -c "import stem" > /dev/null 2>&1;then
  if ! python3 start-hidden-service.py --test --test --test 2> /dev/null;then >&2 echo "  II cannot access tor auth cookie";echo "$RE";exit;fi
  echo "tor-ctrl ${RE#tor-static }"
else
  echo "$RE"
fi
