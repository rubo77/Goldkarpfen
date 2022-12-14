#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
if ! test -f $(basename "$0");then echo "  EE run this script in its folder";exit 1;fi

if test -f ./tmp/darkhttpd.pid && pidof darkhttpd > /dev/null;then
  echo "  II darkhttpd is already running"
else
  darkhttpd archives/ --port "$2" --daemon --log server.log --maxconn 10 --no-server-id --no-listing --pidfile ./tmp/darkhttpd.pid | sed 's/^/  ## /'
fi

if test "$3" = "tor-ctrl";then python3 start-hidden-service.py "$1" "$2" 80;fi
