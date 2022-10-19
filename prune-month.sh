#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
if ! test -f $(basename $0);then echo "  EE run this script in its folder";exit;fi
. ./include.sh
echo "### PRUNE_BEGIN - YOU NEED TO PRUNE TO KEEP YOUR ITP-FILE SANE - anyway ... if you abort you need to fix it by hand and restart"
if sed -n "4,4p" "$2" | ag "^#";then echo "  II nothing to prune"; return; fi
FIRST=$(( ${1#0}  +1 ))
LAST=$(date --utc +"%m") 
if test $LAST -lt $FIRST;then
  for I in $(seq $FIRST 12);do
    MONTH_TO_PRUNE=$(printf "%02i\n" $I)
    ag "^$MONTH_TO_PRUNE\." "$2"
  done
  for I in $(seq 01 $LAST);do
    MONTH_TO_PRUNE=$(printf "%02i\n" $I)
    ag "^$MONTH_TO_PRUNE\." "$2"
  done
else
  for I in $(seq $FIRST $LAST);do
    MONTH_TO_PRUNE=$(printf "%02i\n" $I)
    ag "^$MONTH_TO_PRUNE\." "$2"
  done
fi
echo "### PRUNE_END"
echo -n "[c]-continue [a]-abort [Return] >"
read T_CONFIRM;if test "$T_CONFIRM" != "c";then echo;echo "  II aborted";exit 1;fi
echo "  ## ... just to be sure ..."
echo -n "[c]-continue [a]-abort [Return] >"
read T_CONFIRM;if test "$T_CONFIRM" != "c";then echo;echo "  II aborted";exit 1;fi
echo
if test $LAST -lt $FIRST;then
  for I in $(seq $FIRST 12);do
    MONTH_TO_PRUNE=$(printf "%02i\n" $I)
    sed -i "/^$MONTH_TO_PRUNE\./d" "$2"
  done
  for I in $(seq 01 $LAST);do
    MONTH_TO_PRUNE=$(printf "%02i\n" $I)
    sed -i "/^$MONTH_TO_PRUNE\./d" "$2"
  done
else
  for I in $(seq $FIRST $LAST);do
    MONTH_TO_PRUNE=$(printf "%02i\n" $I)
    sed -i "/^$MONTH_TO_PRUNE\./d" "$2"
  done
fi
exit 0
