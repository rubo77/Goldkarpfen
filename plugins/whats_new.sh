#GPL-3 - See LICENSE file for copyright and license details.
#V0.4
#Goldkarpfen-1JULSJ5Nnba9So48zi21rpfTuZ3tqNRaFB.itp
USER_PLUGINS_MENU="[w]-whats_new:__USER_WHATSNEW $USER_PLUGINS_MENU"
__USER_WHATSNEW(){
  T_BUF=$(seq 0 7 | sed -e "s/^/ -/" -e "s/$/ days/" | $GK_FZF_CMD)
  if test -z "$T_BUF";then echo "  II empty";return;fi
  T_BUF="$(date -d "$T_BUF" --utc +%m.%d)"
  cd itp-files
  echo "##### POSTS #####"
  ag --noheading --nonumbers "^$T_BUF:\d " *.itp | ag -v "^.*:\d\d\.\d\d:\d \d\d\.\d\d:\d @" | grep -v '^$' |
  while IFS= read -r T_LINE;do
    # alias text
    set "$(echo $T_LINE| __collum 1 '-')" "$(echo $T_LINE | sed 's/^.*itp://')"
    echo "$1" "$2" | tr -d '\n' | ag "^([a-zA-Z0-9]+) "
    echo
  done
  printf "##### COMMENTS #####\n"
  ag --noheading --nonumbers "^$T_BUF:\d \d\d\.\d\d:\d @" *.itp | grep -v '^$' |
  while IFS= read -r T_LINE;do
    # alias alias2 text1 text2
    set "$(echo $T_LINE| __collum 1 '-')" "$(ag $(echo $T_LINE| sed 's/^.*@//' | __collum 1 ) ../cache/aliases | __collum 1)" "$(echo $T_LINE | sed 's/^.*itp://')" "$(echo $T_LINE | sed 's/^.*@.................................. //')"
    echo $2
    echo -n "$1 "
    echo -n "$3" | sed "s/ @.* / \[$2\] /" | awk '{print $1" "$2" "$3}' | tr '\n' ' ' | ag "\[.*\]"
    printf "$4\n"
  done
  cd ..
}
