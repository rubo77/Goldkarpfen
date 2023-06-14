#GPL-3 - See LICENSE file for copyright and license details.
#V0.14
#GKdev-1FHDi5veznUojyHaZQ9wv5dwj5aqZmXYGg.itp
USER_PLUGINS_MENU="[/]-search:__USER_SEARCH $USER_PLUGINS_MENU"
__USER_SEARCH_RESULTS(){
  T_CMD=$(__DOWNLOAD_COMMAND "$1" "$2" || echo "__error_getting_dl_cmd;")
  $T_CMD |
  while IFS= read -r T_LINE; do
    if echo "$T_LINE" | ag "^data/[0-9A-Za-z_\-]*\.[0-9A-Za-z_]*" > /dev/null;then
      echo $(tput rev)$(echo "$T_LINE" | __collum 1)$(tput sgr0)
      echo "$T_LINE" | __collum 2 | sed 's@_@://@'
    else
      echo "$T_LINE" | ag "$T_BUF"
    fi
  done
}
__USER_SEARCH_EDIT(){
  if ! test -f tmp/search_text;then
    echo "" > tmp/search_text
  else
    echo "" >> tmp/search_text
  fi
  echo "#enter your search ; 10 results per page" >> tmp/search_text
  echo "#maximum: 256 chars ; lines with # in the beginnig get ignored ; newlines will replaced with spaces." >> tmp/search_text
  echo "#search will be interpreted as regexp :" >> tmp/search_text
  echo "#use %5C to escape special characters : %5C$ %5C^ %5C( %5C) %5C. %5C[ %5C] (aso)" >> tmp/search_text
  echo "#use sed style character classes : [[:digit:]] [[:alnum:]] (aso)" >> tmp/search_text
  echo "#examples : [[:digit:]]{3} ; ^01%5C..*$ ; <plugin=|<download="  >> tmp/search_text
  $EDITOR tmp/search_text
  if ! __CHECK_INPUT tmp/search_text 256 --post;then echo "  EE input error";rm -f tmp/search_text;return;fi
}

__USER_SEARCH_CHOOSE_ENGINE(){
  set -- "$(grep -v "^#" < search.dat | __collum 2 "#" | pipe_if_not_empty $GK_FZF_CMD)"
  if test -z "$1";then echo "  II empty";return 1;else T_ENGINE=$1;fi
}

__USER_SEARCH(){
  if ! test -f search.dat; then
    echo "gopher://d735f63fvayqysxgbtlwckomiomuwde22warrroy3u7rhveyn6cdgzqd.onion gopher/search.cgi? #Goldkarpfen search (original)" > search.dat
  fi
  T_PAGE=0;T_CHANGED="yes"
  __USER_SEARCH_CHOOSE_ENGINE || return
  __USER_SEARCH_EDIT
  while true;do
    if test "$T_CHANGED" = "yes";then
      set -- "$(sed -n '1p' tmp/search_text)"
      T_BUF=$1
      T_BUF2=$(echo "$T_BUF" | sed -e 's/[[:blank:]]/%20/g' -e 's/\[/%5B/g' -e 's/\]/%5D/g' -e 's/{/%7B/g' -e 's/}/%7D/g')
      echo "  ## searching for : $T_BUF ($T_BUF2) page:$T_PAGE"
      set -- "$T_BUF2" $(grep "$T_ENGINE$" search.dat | head -n 1)
      __USER_SEARCH_RESULTS "$2" "$3$1&page=$T_PAGE"
      T_CHANGED=
    fi
    printf "\n  $(tput bold)MM SUBMENU: search$(tput sgr0)  [/]-new_search [n]-next [p]-previous [s]-choose_engine [q]-return > " | fold -s -w "$GK_COLS"
    $GK_READ_CMD CHAR ;printf "\n"
    case "$CHAR" in
      n) T_PAGE=$((T_PAGE + 1)) ; T_CHANGED="yes";;
      p) T_PAGE=$((T_PAGE - 1));if test "$T_PAGE" -lt 0;then T_PAGE=0;T_CHANGED=;else T_CHANGED="yes";fi ;;
      /) T_PAGE=0;__USER_SEARCH_EDIT ; T_CHANGED="yes";;
      s) __USER_SEARCH_CHOOSE_ENGINE || return; T_CHANGED="yes";;
      q) break ;;
      *) echo "  EE wrong key" ; T_CHANGED=;;
    esac
  done
}
