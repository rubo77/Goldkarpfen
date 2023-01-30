#GPL-3 - See LICENSE file for copyright and license details.
USER_PLUGINS_MENU="[a]-add_stream_url:__USER_ADD $USER_PLUGINS_MENU"
__USER_ADD(){
  set -- "$(printf -- "$(if ! test "$ITPFILE" = "$OWN_STREAM";then head -n 1 "$ITPFILE" | ag -o '<url1=(\bhttp\b|\bgopher\b).*>' | ag '://[0-9A-Za-z]{1,80}\..*>' | sed 's/>$/> url1/';fi)\n$(ag --no-numbers "<node=.*>" "$ITPFILE")" | sed -e "s/^.*<.*=//" -e "s/>//" | grep -v '^$' | pipe_if_not_empty $GK_FZF_CMD | __collum 1)"
  if test -z "$1";then echo "  II empty";return;fi
  if grep "$1" nodes.dat;then
    echo "  II this url is already in your node list"
  else
    echo "  ?? are you sure to add $1 to nodes.dat (y/n) >"
    $GK_READ_CMD T_CONFIRM
    if test "$T_CONFIRM" != "y";then return;fi
    echo $1 >> nodes.dat || exit
  fi
  return
}

USER_PLUGINS_MENU="[h]-add_header_tag:__USER_HEADER $USER_PLUGINS_MENU"
__USER_HEADER(){
  if head -n 1 "$OWN_STREAM" | ag -Q '<url1=';then
    echo "  II you have already a url1 header tag - edit it with [!]"
  else
    printf "\nONION :\n"
    echo "  II retrieve your onion hostname with: sudo cat /var/lib/tor/$OWN_ADDR/hostname"
    echo "  II keep a backup of this folder: /var/lib/tor/$OWN_ADDR" | ag "."
    echo "  url1-format : [http|gopher]://_a_lot_of_numbers_and_characters_.onion"
    printf "\nI2P :\n"
    echo "  II keep a backup of your i2p tunnel configuration" | ag "."
    echo "  url1-format : [http|gopher]://_a_lot_of_numbers_and_characters_.i2p"
    printf "\n  ?? enter your url1 >"
    read T_BUF
    printf "  ?? are you sure to add this tag to your itp-header? <url1=$T_BUF> (y/n) >"
    $GK_READ_CMD T_CONFIRM
    if test "$T_CONFIRM" != "y";then return;fi
    echo; sed -i "1s%^#ITP%#ITP <url1=$T_BUF>%" "$OWN_STREAM" || exit
    __OWN_SHA_SUM_UPDATE
  fi
  return
}

USER_PLUGINS_MENU="[A]-sync_all:__USER_SYNC_ALL $USER_PLUGINS_MENU"
__USER_SYNC_ALL(){
  set -- "$(printf "ALL\n$(ag --no-numbers -v "^#" < nodes.dat)" | grep -v "^$" | __collum 1 | pipe_if_not_empty $GK_FZF_CMD)"
  if test -z "$1";then echo "  II empty";return;fi
  if test "$1" = "ALL";then set -- ".";fi
  if test -f my-sync-from-nodes.sh;then ./my-sync-from-nodes.sh "--pattern=$1" || exit;else ./sync-from-nodes.sh "--pattern=$1" || exit;fi
}
