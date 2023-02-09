#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
# The original Goldkarpfen search engine
cd __itp-files-path__ || exit 1
# edit __itp-files-path__ accordingly
set -- "$2"
PAGE=$(echo "$1" | ag -o " P[[:digit:]]*$")
if test -z "$PAGE";then
  LINE1=1
  LINE2=10
else
  PAGE=${PAGE#*P}
  PAGE=$(echo "$PAGE 0 + p" | dc)
  #echo $PAGE
  LINE1=$(echo "$PAGE 10 * 1 + p" | dc)
  LINE2=$(echo "$LINE1 9 + p" | dc)
  set -- "$(echo "$1" | sed "s/ P$PAGE$//")"
fi
ag --silent -m 3 --heading --nonumbers "$1" *.itp | grep -v '^$' | sed -n "$LINE1,$LINE2 p"
# or use a list of itp-files instead of *.itp
# NOTE : designed to work with for 15 search streams
exit 0
