#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
if ! test -f $(basename "$0");then echo "  EE run this script in its folder";exit 1;fi
set -- "$1" "$2" "$(cat cache/darkhttpd.pid 2> /dev/null)"
if test -f cache/darkhttpd.pid && ps ax | ag "^ *$3 " > /dev/null; then kill "$3" ; echo "  ## stopping darkhttpd";fi

if test "$2" = "tor-ctrl";then python3 stop-hidden-service.py "$1";else sleep 0.2;fi

if pgrep darkhttpd; then
  kill $(ps aux | ag "darkhttpd.*--port $(sed -n '4p' Goldkarpfen.config)" | awk '{print $2}') 2> /dev/null
fi
