#GPL-3 - See LICENSE file for copyright and license details.
#V0.12
#prt-01pJFCF3YGfyNgEDDNWHbBUMyeS2Rkgpux.itp
USER_PLUGINS_MENU="[I]-ICT:__USER_ICT $USER_PLUGINS_MENU"
__ICT_SHOW_CARD(){
  clear
  COUNTER=0
  ag --no-numbers --no-filename -A 9 "$1" archives/share/data.json | sed -e 's/^.*"://' -e 's/,$//' -e 's/"//g' -e 's/^ *//' -e 's/ *$//' |
  while IFS= read -r LINE; do
    if test $COUNTER = 1;then
      ___NAME="$LINE"
    elif test $COUNTER = 2;then
      ___COST="$LINE"
    elif test $COUNTER = 3;then
      ___COLOR="$LINE"
    elif test $COUNTER = 4;then
      ___TYPE="$LINE"
    elif test $COUNTER = 5;then
      ___BODY="$LINE"
    elif test $COUNTER = 6;then
      ___STRENGTH="$LINE"
    elif test $COUNTER = 7;then
      ___EXTRA="$(echo "$LINE" | sed 's/^ //')"
    elif test $COUNTER = 8;then
      ___RULE_TITLE="$LINE"
    elif test $COUNTER = 9;then
      ___RULE="$LINE"
      echo
      printf "%-10s" "___ $(echo $1 | __collum 2 | sed 's/,//')"
      if ! test -z $___COLOR;then
        T_BUF1="$(echo  "41-red 42-green 43-land 44-blue 46-sky 100-artifact 107-white 107-dark_white 107-light_white 40-black 40-light_black 33-blank 33-nono" | tr ' ' '\n' | ag "\b.*-$___COLOR\b" | awk -F "-" '{print $1}')"
        printf "\033["$T_BUF1"m [                           ] \033[0m\n"
      else
        printf "\n"
      fi
      printf "%-31s" "$(echo "$___NAME" | sed 's/&#9608;/█/g')"
      printf "%9s\n" "[$___COST]"
      echo
      echo
      echo "$___TYPE" | sed 's/&#9608;/█/g'
      echo
      printf "$(echo "$___BODY" | sed 's/<br>/\n/g')" | sed -e 's/&#8328;/₈/g' -e 's/&#8327;/₇/g' -e 's/&#8326;/₆/g' -e 's/&#8324;/₄/g' -e 's/&#8322;/₂/g' -e 's/&#8321;/₁/g' -e 's/&#9608;/█/g' -e 's/&nbsp;/ /g' | fold -w 37 -s | sed 's/^/  /'
      echo
      echo "„$___EXTRA“" | ag -v '„“' | fold -w 37 -s | sed 's/^/  /'
      printf "%39s\n" "[$___STRENGTH]"
      echo ; echo "___ REGEL"
      echo "$___RULE_TITLE" | sed -e 's/&#8328;/₈/g' -e 's/&#8327;/₇/g' -e 's/&#8326;/₆/g' -e 's/&#8324;/₄/g' -e 's/&#8322;/₂/g' -e 's/&#8321;/₁/g' -e 's/&#9608;/█/g' -e 's/&nbsp;/ /g' 
      printf "$(echo "$___RULE" | sed 's/<br>/\n/g')" | sed -e 's/&#8328;/₈/g' -e 's/&#8327;/₇/g' -e 's/&#8326;/₆/g' -e 's/&#8324;/₄/g' -e 's/&#8322;/₂/g' -e 's/&#8321;/₁/g' -e 's/&#9608;/█/g' -e 's/&nbsp;/ /g' | fold -w "$T_BUF" -s | sed 's/^/  /'
      break
    fi
    COUNTER=$(echo $COUNTER + 1 | bc)
  done
}

__USER_ICT(){
  T_BUF=$(echo $(tput cols) - 5 | bc)
  if ! test -f archives/share/data.json; then echo "get the ICT-database first : data.json and share-host it.";return;fi
  __ICT_SHOW_CARD "1"
  while true;do
    printf "\n\n  \e[4mMM SUBMENU: ict\e[0m  [/]-search [n]-next [p]-previous [q]-return > "
    $GK_READ_CMD CHAR ;printf "\r"
    case "$CHAR" in
      "") echo ;;
      /)
        set "$(ag "^ *\"(title|rule|body|extra|rule_title|card_id)" archives/share/data.json | pipe_if_not_empty $GK_FZF_CMD | __collum 1 ":")" # line number
        if ! test -z "$1";then
          set "$(sed -n "1,$1p" archives/share/data.json | ag "\"card_id\":" | tail -n 1)"
          if ! test -z "$1";then __ICT_SHOW_CARD "$1";else echo "empty";fi
        fi
      ;;
      n)
        if test -z "$1"; then 
          set '"card_id": 0,'
        fi
        set "$(ag --no-numbers --no-filename "\"card_id\":" archives/share/data.json | ag -A 1 "$1" | tail -n 1)"
        __ICT_SHOW_CARD "$1"
        if test "$1" = '"card_id": 0,';then echo "first card";fi
      ;;
      p)
        if test -z "$1"; then 
          set '"card_id": 27791,'
        fi
        set "$(ag --no-numbers --no-filename "\"card_id\":" archives/share/data.json | ag -B 1 "$1" | head -n 1)"
        __ICT_SHOW_CARD "$1"
        if test "$1" = '"card_id": 27791,';then echo "first card";fi
      ;;
      q) break ;;
    esac
  done
}
