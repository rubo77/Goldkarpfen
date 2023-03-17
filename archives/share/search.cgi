#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
#V0.2
# The original Goldkarpfen search engine
cd __itp-files-path__ || exit 1 # edit __itp-files-path__ accordingly
set -- "${2%&page=*}" "$(echo "$2" | ag -o "page=\d*$")"
#echo "search : $1 $2"
if test "$(printf "%i" "${2#page=}")" = "${2#page=}";then PAGE=${2#page=};else PAGE=;fi
if test -z "$PAGE";then
  LINE1=1
  LINE2=10
else
  PAGE=$(echo "$PAGE 0 + p" | dc)
  LINE1=$(echo "$PAGE 10 * 1 + p" | dc)
  LINE2=$(echo "$LINE1 9 + p" | dc)
  set -- "$(echo "$1" | sed "s/ P$PAGE$//")"
fi
ag --silent -m 3 --heading --nonumbers "$1" *.itp | grep -v '^$' | sed -n "$LINE1,$LINE2 p"
# or use a list of itp-files instead of *.itp
# NOTE : designed to work with for 15 search streams
exit 0
