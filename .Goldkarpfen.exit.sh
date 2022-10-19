#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
if test -f ./my-stop-services.sh;then
  ./my-stop-services.sh $OWN_ADDR
elif test "$GK_MODE" = "tor";then
  ./stop-services.sh $OWN_ADDR
fi
rm -Rf tmp/*
