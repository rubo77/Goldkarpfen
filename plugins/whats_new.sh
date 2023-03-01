#GPL-3 - See LICENSE file for copyright and license details.
#V0.19
#Goldkarpfen-1JULSJ5Nnba9So48zi21rpfTuZ3tqNRaFB.itp
__LAST_DAYS(){
  __L1="26 31";__L2="25 30";__L3="24 29";__L4="23 28"
  set -- $(date "+%Y %m %d")
  if test "${3#0}" -gt 6;then
    printf "$2.%02d\n" $(seq "$((${3#0} - 6))" "$3") | sort -r
  else
    printf "$2.%02d\n" $(seq 1 "${3#0}") | sort -r
    if test "$2" = "03";then if date -d "$1-02-29" > /dev/null 2>&1;then __SEQ=$__L3;else __SEQ=$__L4;fi
    elif test "$2" = "05" -o "$2" = "07" -o "$2" = "10" -o "$2" = "12";then
      __SEQ=$__L2
    else
      __SEQ=$__L1
    fi
    __M=$(( ${2#0} - 1 )); if test "$__M" = 0;then __M=12;fi;__M=$(printf "%02d\n" "$__M")
    printf "$__M.%02d\n" $(seq $__SEQ | tail -n $((7 - $3)) | sort -r)
  fi
}

USER_PLUGINS_MENU="[w]-wassup:__USER_WHATSNEW $USER_PLUGINS_MENU"
__USER_WHATSNEW(){
  T_BUF=$(__LAST_DAYS | $GK_FZF_CMD)
  if test -z "$T_BUF";then echo "  II empty";return;fi
  cd itp-files || exit
  echo "##### POSTS #####"
  ag --noheading --nonumbers "^$T_BUF:\d " *.itp | ag -v "^.*:\d\d\.\d\d:\d \d\d\.\d\d:\d @" | grep -v '^$' |
  while IFS= read -r T_LINE;do
    # alias text
    set -- "${T_LINE%%-*}" "${T_LINE##*itp:}"
    echo "$(tput rev)[$1]$(tput sgr0) $2" | sed 's/\&bsol;/\\/g' |fold -w "$GK_COLS" -s
  done
  printf "##### COMMENTS #####\n"
  ag --noheading --nonumbers "^$T_BUF:\d \d\d\.\d\d:\d @" *.itp | grep -v '^$' |
  while IFS= read -r T_LINE;do
    # alias1 alias2
    set -- "${T_LINE%%-*}" "$(ag "$(echo "${T_LINE#*@}" | __collum 1 )" ../cache/aliases | __collum 1)"
    echo "$T_BUF [$1] -> $(tput rev)[$2]$(tput sgr0) ${T_LINE#*@?????????????????????????????????? }" | sed 's/\&bsol;/\\/g' | fold -w "$GK_COLS" -s
  done
  cd ..
}
