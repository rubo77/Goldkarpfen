#GPL-3 - See LICENSE file for copyright and license details.
#V0.16
#Goldkarpfen-1JULSJ5Nnba9So48zi21rpfTuZ3tqNRaFB.itp
if ! test "$GK_MODE" = "PASSIVE";then
  USER_PLUGINS_MENU="[d]-download:__USER_DOWNLOAD $USER_PLUGINS_MENU"
  __USER_DOWNLOAD(){
    mkdir -p downloads
    
    # URL DL_LINK
    set "$(sed -n "1p" $ITPFILE | sed -e "s/^.*<url1=//" -e "s/>.*//")" "$(ag --no-numbers "<download=.*>" $ITPFILE | sed -e "s/^.*<.*=//" -e "s/>/ /" | pipe_if_not_empty $GK_FZF_CMD)"

    if test -z $1;then echo "  II the stream has no url1 tag"; return;fi
    if test -z "$2";then echo "  II empty";return;fi
    
    # URL FILENAME
    set "$1" "$(echo $2 | awk '{print $1}')"

    if test -f downloads/"$(basename $2)";then
      echo -n "  ?? file exists - overwrite? (Y/n) >"
      $GK_READ_CMD T_CONFIRM;if test "$T_CONFIRM" != "Y";then printf "\n  II aborted\n";return;else echo;fi
    fi

    echo "  ## downloading" $2
    T_CMD=$(__DOWNLOAD_COMMAND "$1" "$2" || echo "__error_getting_dl_cmd;")
    if $T_CMD -o downloads/"$(basename $2)";then
      echo -n "  ?? do you want to share-host this file? (y/n) >"
      $GK_READ_CMD T_BUF;echo
      if test "$T_BUF" != "y";then return;fi
      if test -f archives/"$2";then
        echo -n "  ?? file exists - overwrite? (Y/n) >"
        $GK_READ_CMD T_CONFIRM;if test "$T_CONFIRM" != "Y";then printf "\n  II aborted\n";return;else echo;fi
      fi
      mkdir -p archives/share
      echo "  ## copying $2 to archives/share"; cp downloads/"$(basename $2)" archives/share
      echo "  II add a post with this: <download=share/$(basename $2)>"
    fi
  }
fi
