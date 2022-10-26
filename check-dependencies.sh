#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
RE="tor"
if ! which ss curl darkhttpd > /dev/null;then RE="PASSIVE";fi
if ! python3 -c "import stem" > /dev/null 2>&1 || ! which python3 > /dev/null 2>&1;then >&2 echo "  II python-stem and/or python3 not found (ignore this if you are running i2p only or tor-static)";RE="PASSIVE";fi
if ! test -f /var/lib/tor/control_auth_cookie;then >&2 echo "  II cannot access tor auth cookie (ignore this if you are running i2p only or tor-static)";RE="PASSIVE";fi
if test "$RE" = "PASSIVE" && which curl > /dev/null 2>&1 && ss -tulpn | ag "127.0.0.1:4444" > /dev/null 2>&1;then RE="i2p";fi
if test "$RE" = "PASSIVE" && which curl > /dev/null 2>&1 && ss -tulpn | ag "127.0.0.1:9050" > /dev/null 2>&1;then RE="tor-passive";fi
if test -z $EDITOR;then echo >&2 "EDITOR env var is empty.";RE="ERROR";fi
if ! which fzf > /dev/null 2>&1  && ! which fzy > /dev/null 2>&1 ;then >&2 echo "  EE fzf or fzy not found";RE="ERROR";fi
if ! which pidof ps tput gzip dd du mktemp xxd ag dc openssl more fold awk sed grep basename sha512sum tr cat touch tail head cmp tar date sort uniq wc file pwd diff> /dev/null;then RE="ERROR";fi
echo $RE
