#GPL-3 - See LICENSE file for copyright and license details.
#V0.16
#Goldkarpfen-1JULSJ5Nnba9So48zi21rpfTuZ3tqNRaFB.itp
USER_PLUGINS_MENU="[w]-wassup:__USER_WHATSNEW $USER_PLUGINS_MENU"
__USER_WHATSNEW(){
  T_BUF=$(seq 0 7 | sed -e "s/^/ -/" -e "s/$/ days/" | $GK_FZF_CMD)
  if test -z "$T_BUF";then echo "  II empty";return;fi
  T_BUF="$(date -d "$T_BUF" --utc +%m.%d)"
  cd itp-files || exit
  echo "##### POSTS #####"
  ag --noheading --nonumbers "^$T_BUF:\d " *.itp | ag -v "^.*:\d\d\.\d\d:\d \d\d\.\d\d:\d @" | grep -v '^$' |
  while IFS= read -r T_LINE;do
    # alias text
    set -- "${T_LINE%%-*}" "${T_LINE##*itp:}"
    echo "$(tput rev)[$1]$(tput sgr0) $2" | fold -w "$GK_COLS" -s
  done
  printf "##### COMMENTS #####\n"
  ag --noheading --nonumbers "^$T_BUF:\d \d\d\.\d\d:\d @" *.itp | grep -v '^$' |
  while IFS= read -r T_LINE;do
    # alias1 alias2
    set -- "${T_LINE%%-*}" "$(ag "$(echo "${T_LINE#*@}" | __collum 1 )" ../cache/aliases | __collum 1)"
    echo "$T_BUF [$1] -> $(tput rev)[$2]$(tput sgr0) ${T_LINE#*@?????????????????????????????????? }" | fold -w "$GK_COLS" -s
  done
  cd ..
}
