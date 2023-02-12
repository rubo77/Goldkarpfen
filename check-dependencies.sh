#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
__WHICH(){
  for PROG in $1;do
    if ! command -v "$PROG" > /dev/null;then echo >&2 "  EE $PROG not found";return 1;fi
  done
}
RE=
if test -z $EDITOR;then echo >&2 "EDITOR env var is empty.";RE="ERROR";fi
if ! command -v fzf > /dev/null 2>&1  && ! command -v fzy > /dev/null 2>&1 ;then >&2 echo "  EE fzf or fzy not found";RE="ERROR";fi
if ! __WHICH "pidof ps tput gzip dd du mktemp xxd ag dc openssl fold awk sed grep basename sha512sum tr cat touch tail head cmp tar date sort uniq wc file pwd diff ss";then RE="ERROR";fi
if test "$RE" = "ERROR";then echo "$RE";exit 1;else RE="ok";fi
if __WHICH "curl";then RE="get $RE";fi
if __WHICH "darkhttpd";then RE="host $RE";fi
if ss -tulpn | ag "127.0.0.1:4444" > /dev/null 2>&1;then RE="i2p $RE";fi
if ss -tulpn | ag "127.0.0.1:9050|127.0.0.1:9150" > /dev/null 2>&1;then RE="tor-static $RE";fi
if python3 -c "import stem" > /dev/null 2>&1;then
  if ! python3 start-hidden-service.py --test --test --test 2> /dev/null;then >&2 echo "  II cannot access tor auth cookie";echo "$RE";exit;fi
  echo "tor-ctrl ${RE#tor-static }"
else
  echo "$RE"
fi
