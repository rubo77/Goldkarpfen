#GPL-3 - See LICENSE file for copyright and license details.
USER_PLUGINS_MENU="[a]-nodes:__USER_ADD $USER_PLUGINS_MENU"
__USER_ADD(){
  set -- "$(printf -- "GET_TRACKER_DATA\n$(if ! test "$ITPFILE" = "$OWN_STREAM";then ag -m 1 -o '^#ITP.*<url1=[a-z]{3,6}://[A-Za-z0-9.]*[.:][A-Za-z0-9]{1,5}>' "$ITPFILE" 2> /dev/null | sed 's/>$/> url1 of selected stream/';fi)\n$(ag --no-filename --no-numbers "<node=[a-z]{3,6}://[A-Za-z0-9.]*[.:][A-Za-z0-9]{1,5}>" itp-files/*.itp)" | sed -e "s/^.*<.*=//" -e "s/>//" | grep -v '^$' | pipe_if_not_empty $GK_FZF_CMD | __collum 1)"
  if test -z "$1";then echo "  II empty";return;fi
  if test "$1" = "GET_TRACKER_DATA";then
    set -- "$(echo $(ag -o --no-numbers '^[a-z]{3,6}://[A-Za-z0-9.]*[.:][A-Za-z0-9]{1,5}|^#_.*_#$' nodes.dat) | sed -e 's/$/ /' -e 's/_# /=/g' -e 's/#_/ /g' | tr ' ' '\n' | grep -E -v '^.*=$|#|^$' | pipe_if_not_empty $GK_FZF_CMD)"
    set -- "${1##*=}"
    if test -z "$1";then echo "  II empty";return;fi
    T_CMD=$(__DOWNLOAD_COMMAND "$1" "tracker.dat" || echo "__error_getting_dl_cmd;")
    set -- "$($T_CMD | ag -o "^[a-z]{3,6}://[A-Za-z0-9.]*[.:][A-Za-z0-9]{1,5} last_success:$(date +%y-%m-%d)" | grep -v "^$" | pipe_if_not_empty $GK_FZF_CMD --prompt="__ADD NODE:"| __collum 1)"
    if test -z "$1";then echo "  II empty";return;fi
  fi
  if grep "$1" nodes.dat;then
    echo "  II this url is already in your node list"
  else
    echo "  ?? are you sure to add $1 to nodes.dat y/[n] >"
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
    set -- "$(ag -m 1 -o "^#ITP.*<url1=[a-z]{3,6}://[A-Za-z0-9.]*[.:][A-Za-z0-9]{1,5}>" "$ITPFILE" 2> /dev/null)"
    if test -z "$1";then echo "  EE your url1 header tag is not valid";return;fi
    if ! command -v qrencode > /dev/null 2>&1;then echo "  II install libqrencode (or qrencode) for qrcode";return;fi
    set -- "${1#*<url1=}"; set -- "${1%>*}"
    echo -n "$(tput setab 0)$(tput setaf 15)";qrencode "$1" -t UTF8;echo -n "$(tput sgr0)"
  else
    printf "\n  ?? enter your url1 >"
    read T_BUF
    if ! echo "$T_BUF" | ag "^[a-z]{3,6}://[A-Za-z0-9.]*[.:][A-Za-z0-9]{1,5}$" > /dev/null;then echo "  EE input error";return;fi
    echo; sed -i "1s%^#ITP%#ITP <url1=$T_BUF>%" "$OWN_STREAM" || exit
    __OWN_SHA_SUM_UPDATE
  fi
}

USER_PLUGINS_MENU="[d]-download:__USER_DOWNLOAD $USER_PLUGINS_MENU"
__USER_DOWNLOAD(){
  mkdir -p downloads || exit
  # URL DL_LINK
  set -- "$(ag -m 1 -o "^#ITP.*<url1=[a-z]{3,6}://[A-Za-z0-9.]*[.:][A-Za-z0-9]{1,5}>" "$ITPFILE" 2> /dev/null | sed -e "s/^.*<url1=//" -e "s/>.*//")" "$(ag --no-numbers "<download=[a-zA-Z0-9._\-/]*>" "$ITPFILE" | sed -e "s/^.*<.*=//" -e "s/>/ /" | pipe_if_not_empty $GK_FZF_CMD)"
  if test -z "$2";then echo "  II empty";return;fi
  set -- "$1" "${2%% *}"
  if echo "$2" | ag '^.*://' > /dev/null;then
    # FILENAME
    set -- "$(echo "$2" | sed -e 's@^.*://@@' -e 's@/@ @' | awk '{print $2}')" "$2"
    # URL FILENAME
    set -- "${2%/$1}" "$1"
  else
    if test -z "$1";then echo "  II the stream has no url1 tag"; return;fi
  fi

  if test -f downloads/"$(basename "$2")";then
    echo -n "  ?? file exists - overwrite? Y/[N] >"
    $GK_READ_CMD T_CONFIRM;if test "$T_CONFIRM" != "Y";then printf "\n  II aborted\n";return;else echo;fi
  fi

  echo "  ## downloading $2"
  T_CMD=$(__DOWNLOAD_COMMAND "$1" "$2" || echo "__error_getting_dl_cmd;")
  $T_CMD -o downloads/"$(basename $2)" || return
    echo -n "  ?? do you want to share-host this file? y/[n] >"
    $GK_READ_CMD T_BUF;echo
    if test "$T_BUF" != "y";then return;fi
    if test -f archives/"$2";then
      echo -n "  ?? file exists - overwrite? Y/[N] >"
      $GK_READ_CMD T_CONFIRM;if test "$T_CONFIRM" != "Y";then printf "\n  II aborted\n";return;else echo;fi
    fi
    mkdir -p archives/share || exit
    cp -v downloads/"$(basename $2)" archives/share || return
    echo "  II add a post with this: <download=share/$(basename $2)>"
}

USER_PLUGINS_MENU="[X]-exec:__USER_EXEC $USER_PLUGINS_MENU"
__USER_EXEC(){
  # URL DL_LINK
  set -- "$(ag -o --no-numbers "<exec=.*>" "$ITPFILE" | sed -e "s/<exec=//" -e "s/>$//" | pipe_if_not_empty $GK_FZF_CMD)"
  if test -z "$1";then echo "  II empty";return;fi
  echo -n "command : ";ag --no-numbers --no-color -o -Q "$1" "$ITPFILE" | sed 's/\&bsol;/\\/g'
  printf "  II executing code can be dangerous!\n  II be sure to understand the command!\n" | ag "."
  echo -n "  ?? really execute? Y/[N] [Return] >"; read T_CONFIRM;if test "$T_CONFIRM" != "Y";then printf "\n  II aborted\n";return;else echo;fi
  eval "$(ag --no-numbers --no-color -o -Q "$1" "$ITPFILE" | sed 's/\&bsol;/\\/g')"
}
