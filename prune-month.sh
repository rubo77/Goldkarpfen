#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
if ! test -f $(basename $0);then echo "  EE run this script in its folder";exit;fi
. ./include.sh
T_BUF="0"
FIRST=$(( ${1#0}  +1 )); LAST=$(date --utc +"%m")
if test $LAST -lt $FIRST;then SEQUENCE="$(seq $FIRST 12) $(seq 01 $LAST)";else SEQUENCE="$(seq $FIRST $LAST)";fi
SEQUENCE=$(echo $SEQUENCE | tr '\n' ' ')
echo "### PRUNE_BEGIN - YOU NEED TO PRUNE TO KEEP YOUR ITP-FILE SANE - anyway ... if you abort you need to fix it by hand and restart"
for I in $SEQUENCE;do
  MONTH_TO_PRUNE=$(printf "%02i\n" $I)
  if ag "^$MONTH_TO_PRUNE\." "$2";then T_BUF="1";fi
done
if test $T_BUF = "0";then echo "  II nothing to prune"; exit 0; fi
echo "### PRUNE_END"
echo "### months to prune: $SEQUENCE"
echo -n "[c]-continue [a]-abort [Return] >"
read T_CONFIRM;if test "$T_CONFIRM" != "c";then echo;echo "  II aborted";exit 1;fi
echo "  ## ... just to be sure ..."
echo -n "[c]-continue [a]-abort [Return] >"
read T_CONFIRM;if test "$T_CONFIRM" != "c";then echo;echo "  II aborted";exit 1;fi
echo
for I in $SEQUENCE;do
  MONTH_TO_PRUNE=$(printf "%02i\n" $I)
  sed -i "/^$MONTH_TO_PRUNE\./d" "$2"
done
exit 0
