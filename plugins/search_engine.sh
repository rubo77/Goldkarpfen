#GPL-3 - See LICENSE file for copyright and license details.
#V0.8
#GKdev-1FHDi5veznUojyHaZQ9wv5dwj5aqZmXYGg.itp
USER_PLUGINS_MENU="[s]-search:__USER_SEARCH $USER_PLUGINS_MENU"
__USER_SEARCH(){
  if ! test -f search.dat; then
    echo "gopher://d735f63fvayqysxgbtlwckomiomuwde22warrroy3u7rhveyn6cdgzqd.onion gopher/search.cgi? #Goldkarpfen search (original)" > search.dat
  fi
  if ! test -f tmp/search_text;then
    echo "" > tmp/search_text
  else
    echo "" >> tmp/search_text
  fi
  echo "#enter your search ; 10 results per page ; add page number at the end like : [[:space:]]P2" >> tmp/search_text
  echo "#maximum: 256 chars ; lines with # in the beginnig get ignored ; newlines will replaced with spaces." >> tmp/search_text
  echo "#search will be interpreted as regexp :" >> tmp/search_text
  echo "#use %5C to escape special characters : %5C$ %5C^ %5C( %5C) %5C. %5C[ %5C] (aso)" >> tmp/search_text
  echo "#use sed style character classes : [[:digit:]] [[:alnum:]] (aso)" >> tmp/search_text
  echo "#examples : [[:digit:]]{3} ; ^01%5C..*$ P3 ; <plugin=|<download="  >> tmp/search_text
  $EDITOR tmp/search_text
  if ! __CHECK_INPUT tmp/search_text 256 --post;then echo "  EE input error";rm -f tmp/search_text;return;fi
  set -- "$(sed -n '1p' tmp/search_text)"
  T_BUF=$1
  T_BUF2=$(echo "$T_BUF" | sed -e 's/[[:blank:]]/%20/g' -e 's/\[/%5B/g' -e 's/\]/%5D/g' -e 's/{/%7B/g' -e 's/}/%7D/g')
  echo "  ## searching for : $T_BUF ($T_BUF2)"
  set -- "$(grep -v "^#" < search.dat | __collum 2 "#" | pipe_if_not_empty $GK_FZF_CMD)"
  if test -z "$1";then echo "  II empty";return;fi
  set -- "$T_BUF2" $(grep "$1$" search.dat | head -n 1)
  T_CMD=$(__DOWNLOAD_COMMAND "$2" "$3$1" || echo "__error_getting_dl_cmd;")
  T_BUF=$(echo "$T_BUF" | sed 's/ P[[:digit:]]*$//')
  $T_CMD |
  while IFS= read -r T_LINE; do
    if echo $T_LINE | ag "^[0-9A-Za-z_]{1,12}-[0-9A-Za-z]{34}\.itp" > /dev/null;then
      echo $(tput rev)$(echo "$T_LINE" | __collum 1)$(tput sgr0)
      echo "$T_LINE" | __collum 2 | sed 's@_@://@'
    else
      echo "$T_LINE" | ag "$T_BUF"
    fi
  done
}

