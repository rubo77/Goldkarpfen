#GPL-3 - See LICENSE file for copyright and license details.
USER_PLUGINS_MENU="[a]-nodes:__USER_ADD $USER_PLUGINS_MENU"
__USER_ADD(){
  set -- "$(printf -- "GET_TRACKER_DATA\n$(if ! test "$ITPFILE" = "$OWN_STREAM";then head -n 1 "$ITPFILE" | ag -o '<url1=[a-z]{3,6}://[A-Za-z0-9.]*[.:][A-Za-z0-9]{1,5}>' | sed 's/>$/> url1 of selected stream/';fi)\n$(ag --no-filename --no-numbers "<node=[a-z]{3,6}://[A-Za-z0-9.]*[.:][A-Za-z0-9]{1,5}>" itp-files/*.itp)" | sed -e "s/^.*<.*=//" -e "s/>//" | grep -v '^$' | pipe_if_not_empty $GK_FZF_CMD | __collum 1)"
  if test -z "$1";then echo "  II empty";return;fi
  if test "$1" = "GET_TRACKER_DATA";then
    set -- "$(echo $(ag -o --no-numbers '^[a-z]{3,6}://[A-Za-z0-9.]*[.:][A-Za-z0-9]{1,5}|^#_.*_#$' nodes.dat) | sed -e 's/$/ /' -e 's/_# /=/g' -e 's/#_/ /g' | tr ' ' '\n' | grep -E -v '^.*=$|#|^$' | pipe_if_not_empty $GK_FZF_CMD)"
    set -- "${1#*=}"
    if test -z "$1";then echo "  II empty";return;fi
    T_CMD=$(__DOWNLOAD_COMMAND "$1" "tracker.dat" || echo "__error_getting_dl_cmd;")
    set -- "$($T_CMD | ag -o "^[a-z]{3,6}://[A-Za-z0-9.]*[.:][A-Za-z0-9]{1,5} last_success:$(date +%y-%m-%d)" | grep -v "^$" | pipe_if_not_empty $GK_FZF_CMD -p "add node> "| __collum 1)"
    if test -z "$1";then echo "  II empty";return;fi
  fi
  if grep "$1" nodes.dat;then
    echo "  II this url is already in your node list"
  else
    echo "  ?? are you sure to add $1 to nodes.dat (y/n) >"
    $GK_READ_CMD T_CONFIRM
    if test "$T_CONFIRM" != "y";then return;fi
    echo "$1" >> nodes.dat || exit
  fi
  return
}

USER_PLUGINS_MENU="[h]-url1:__USER_HEADER $USER_PLUGINS_MENU"
__USER_HEADER(){
  if head -n 1 "$OWN_STREAM" | ag '<url1=.*>';then
    echo "  II your url1 - edit it with [!]"
    set -- $(head -n 1 "$OWN_STREAM" | ag -o "<url1=[a-z]{3,6}://[A-Za-z0-9.]*[.:][A-Za-z0-9]{1,5}>")
    if test -z "$1";then echo "  EE your url1 header tag is not valid";return;fi
    if ! command -v qrencode > /dev/null 2>&1;then echo "  II install libqrencode (or qrencode) for qrcode";return;fi
    set -- "${1#<url1=}"; set -- "${1%>}"
    qrencode "$1" -t UTF8
  else
    printf "\n  ?? enter your url1 >"
    read T_BUF
    if ! echo "$T_BUF" | ag "^[a-z]{3,6}://[A-Za-z0-9.]*[.:][A-Za-z0-9]{1,5}$" > /dev/null;then echo "  EE input error";return;fi
    echo; sed -i "1s%^#ITP%#ITP <url1=$T_BUF>%" "$OWN_STREAM" || exit
    __OWN_SHA_SUM_UPDATE
  fi
}

USER_PLUGINS_MENU="[A]-_:__USER_SYNC_ALL $USER_PLUGINS_MENU"
__USER_SYNC_ALL(){
  printf "  This way of calling SYNC is deprecated\n  use [S] in the main menu\n" | ag "."
}
