#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
if ! test -f $(basename "$0");then echo "  EE run this script in its folder";exit 1;fi

if test -f cache/darkhttpd.pid;then
  if ps --pid "$(cat cache/darkhttpd.pid)" > /dev/null;then echo "  II darkhttpd is already running";else rm -f cache/darkhttpd.pid;fi
fi
test -f cache/darkhttpd.pid || darkhttpd archives/ --port "$2" --daemon --log server.log --maxconn 10 --no-server-id --no-listing --pidfile cache/darkhttpd.pid | sed 's/^/  ## /'


if test "$3" = "tor-ctrl";then python3 start-hidden-service.py "$1" "$2" 80;fi
