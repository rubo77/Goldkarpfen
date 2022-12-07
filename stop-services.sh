#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
if ! test -f $(basename "$0");then echo "  EE run this script in its folder";exit 1;fi

if test -f ./tmp/darkhttpd.pid && pidof darkhttpd > /dev/null; then kill $(cat ./tmp/darkhttpd.pid);echo "  ## stopping darkhttpd";fi

if test "$2" = "tor-ctrl";then python3 stop-hidden-service.py $1;else sleep 0.2;fi

if ! test -f ./tmp/darkhttpd.pid && pidof darkhttpd; then
  echo "  II there is no darkhttpd.pid but there is still a process running"
  echo "  II (this may be on purpose)"
fi
