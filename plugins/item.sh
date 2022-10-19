#GPL-3 - See LICENSE file for copyright and license details.
#V0.8
#prt-01pJFCF3YGfyNgEDDNWHbBUMyeS2Rkgpux.itp
USER_PLUGINS_MENU="[i]-items:__USER_ITEM $USER_PLUGINS_MENU"
__USER_ITEM(){
  # ITPFILE_ADDR ITEM
  set "$(echo $ITPFILE | __collum 3 "-" | __collum 1 ".")" "$(ag --no-numbers --no-heading --no-filename "\+\[.*\]" itp-files/*.itp | sed -e "s/\+\[.*:D\]/+[:D - Goldkarpfentaler]/" -e 's/^.*\+\[//g' -e 's/\].*//' | sort | uniq | pipe_if_not_empty $GK_FZF_CMD)"
  if test -z "$2";then echo "  II empty";return;fi
  echo " $2 " | ag "."
  if ! test "$2" = ":D - Goldkarpfentaler";then
    T_BUF1=$(ag --no-numbers --no-heading --no-filename "^\d\d\.\d\d:\d \+\[.*\] *$"  "$ITPFILE" | ag -Q "$2" | wc -l)
    T_BUF2=$(ag --no-numbers --no-heading --no-filename "^\d\d\.\d\d:\d \d\d\.\d\d:\d @.* \+\[.*\] *$"  "$ITPFILE" | ag -Q "$2" | wc -l)
    T_BUF3=$(ag --no-numbers --no-heading --no-filename "^\d\d\.\d\d:\d \d\d\.\d\d:\d @$1 \+\[.*\] *$"  itp-files/*.itp | ag -Q "$2" | wc -l)
    T_BUF4=$(echo "$T_BUF1 - $T_BUF2 + $T_BUF3" | bc)
    echo "made     : $T_BUF1"
    echo "given    : $T_BUF2"
    echo "recieved : $T_BUF3"
    echo "________________"
    echo "SUM      : $T_BUF4"
  else
    T_BUF1=$(ag --no-numbers --no-heading --no-filename "^\d\d\.\d\d:\d \+\[.*\] *$"  "$ITPFILE" | ag "\+\[.*:D\]" | sed -e "s/^.*\[//" -e "s/:D\].*//" | sed -e "s/M/000000/" -e "s/k/000/")

    T_BUF2=$(ag --no-numbers --no-heading --no-filename "^\d\d\.\d\d:\d \d\d\.\d\d:\d @.* \+\[.*\] *$"  "$ITPFILE" | ag "\+\[.*:D\]" | sed -e "s/^.*\[//" -e "s/:D\].*//" | sed -e "s/M/000000/" -e "s/k/000/")
    if test -z "$T_BUF1";then T_BUF1=0;fi
    if test -z "$T_BUF2";then T_BUF2=0;fi
    T_BUF4=$(echo "$T_BUF1 - $T_BUF2" | bc)
    echo "made     : $T_BUF1"
    echo "given    : $T_BUF2"
    echo "________________"
    echo "SUM      : $T_BUF4"
  fi
}
