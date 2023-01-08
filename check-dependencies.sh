#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
__WHICH(){
  for PROG in $1;do
    if ! which "$PROG" > /dev/null;then echo >&2 "  EE $PROG not found";return 1;fi
  done
}
RE=
if ! __WHICH which;then RE="ERROR";fi
if test -z $EDITOR;then echo >&2 "EDITOR env var is empty.";RE="ERROR";fi
if ! which fzf > /dev/null 2>&1  && ! which fzy > /dev/null 2>&1 ;then >&2 echo "  EE fzf or fzy not found";RE="ERROR";fi
if ! __WHICH "pidof ps tput gzip dd du mktemp xxd ag bc dc openssl more fold awk sed grep basename sha512sum tr cat touch tail head cmp tar date sort uniq wc file pwd diff ss";then RE="ERROR";fi
if test "$RE" = "ERROR";then echo "$RE";exit 1;else RE="ok";fi
if which "curl" 2>&1;then RE="get $RE";fi
if which "darkhttpd" 2>&1;then RE="host $RE";fi
if ss -tulpn | ag "127.0.0.1:4444" > /dev/null 2>&1;then RE="i2p $RE";fi
if ss -tulpn | ag "127.0.0.1:9050" > /dev/null 2>&1;then RE="tor-static $RE";fi
if ! python3 -c "import stem" > /dev/null 2>&1 || ! which python3 > /dev/null 2>&1;then >&2 echo "  II python-stem and/or python3 not found (ignore this if you are running i2p only or tor-static)";echo "$RE";exit;fi
if ! test -f /var/lib/tor/control_auth_cookie;then >&2 echo "  II cannot access tor auth cookie (ignore this if you are running i2p only or tor-static)";echo "$RE";exit;fi
echo "tor-ctrl ${RE#tor-static }"
