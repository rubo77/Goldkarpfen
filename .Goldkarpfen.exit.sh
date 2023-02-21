#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
if test -f ./my-stop-services.sh;then
  ./my-stop-services.sh "$OWN_ADDR"
elif echo "$GK_MODE" | ag 'host' > /dev/null;then
  ./stop-services.sh "$OWN_ADDR" "$(echo $GK_MODE | __collum 1)"
fi
rm -Rf tmp/*
