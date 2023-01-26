#GPL-3 - See LICENSE file for copyright and license details.
#V0.24
#Goldkarpfen-1JULSJ5Nnba9So48zi21rpfTuZ3tqNRaFB.itp
USER_PLUGINS_MENU="[d]-download:__USER_DOWNLOAD $USER_PLUGINS_MENU"
__USER_DOWNLOAD(){
  mkdir -p downloads || exit
  # URL DL_LINK
  set -- "$(sed -n "1p" $ITPFILE | sed -e "s/^.*<url1=//" -e "s/>.*//")" "$(ag --no-numbers "<download=.*>" $ITPFILE | sed -e "s/^.*<.*=//" -e "s/>/ /" | pipe_if_not_empty $GK_FZF_CMD)"
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
    echo -n "  ?? file exists - overwrite? (Y/n) >"
    $GK_READ_CMD T_CONFIRM;if test "$T_CONFIRM" != "Y";then printf "\n  II aborted\n";return;else echo;fi
  fi

  echo "  ## downloading" $2
  T_CMD=$(__DOWNLOAD_COMMAND "$1" "$2" || echo "__error_getting_dl_cmd;")
  $T_CMD -o downloads/"$(basename $2)" || return
    echo -n "  ?? do you want to share-host this file? (y/n) >"
    $GK_READ_CMD T_BUF;echo
    if test "$T_BUF" != "y";then return;fi
    if test -f archives/"$2";then
      echo -n "  ?? file exists - overwrite? (Y/n) >"
      $GK_READ_CMD T_CONFIRM;if test "$T_CONFIRM" != "Y";then printf "\n  II aborted\n";return;else echo;fi
    fi
    mkdir -p archives/share || exit
    echo "  ## copying $2 to archives/share"; cp downloads/"$(basename $2)" archives/share || return
    echo "  II add a post with this: <download=share/$(basename $2)>"
}
