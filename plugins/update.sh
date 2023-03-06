#GPL-3 - See LICENSE file for copyright and license details.
USER_PLUGINS_MENU="[U]-updGK:__USER_UPDATE $USER_PLUGINS_MENU"
__USER_UPDATE(){
  cd update || exit
  echo "  ## FIRST RUN"
  if ./sync_runtime_files.sh --first-run;then
    sync && if test -f srf.tmp;then mv srf.tmp sync_runtime_files.sh;fi
    echo "  ## SECOND RUN"
    if ./sync_runtime_files.sh;then echo "  II restart your Goldkarpfen now " | ag "."
    else echo "  EE fatal error : it is recommended to exit Goldkarpfen now!";fi
  else
    echo "  II you said no, or something went wrong"
  fi
  cd ..
}

USER_PLUGINS_MENU="[z]-inst_qr:__USER_INQR $USER_PLUGINS_MENU"
__USER_INQR(){
  set -- "$(printf "local\nurl1\n" | pipe_if_not_empty $GK_FZF_CMD)"
  if test -z "$1";then echo "  II empty";return;fi
  if test "$1" = "local";then
    echo "  ?? enter your local address"
    read T_BUF3
    if ! echo "$T_BUF3" | ag "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$|^[a-z]{3,6}://\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$" > /dev/null;then echo "  EE input error";return;fi
    set -- "$T_BUF3:$(sed -n '4 p' Goldkarpfen.config)"
    T_BUF4="curl tor";T_BUF5="tor --quiet &";T_BUF6="tor"
  else
      set -- $(head -n 1 "$OWN_STREAM" | ag -o "<url1=[a-z]{3,6}://[A-Za-z0-9.]*[.:][A-Za-z0-9]{1,5}>")
      if test -z "$1";then echo "  EE your url1 header tag is not valid";echo "  II p2p-installer only for tor/i2p";return;fi
      set -- "${1#<url1=}"; set -- "${1%>}"
      if echo "$1" | ag "\.i2p$" > /dev/null;then T_BUF4="curl i2pd";T_BUF5="i2pd --daemon --loglevel=none &";T_BUF6="i2pd";else T_BUF4="curl tor";T_BUF5="tor --quiet &";T_BUF6="tor";fi
  fi
  T_CMD=$(__DOWNLOAD_COMMAND "$1" "share/gki.sh" || echo "__error_getting_dl_cmd;");T_CMD=$(echo $T_CMD | sed -e "s/--progress-bar //")
  echo -n "$(tput setab 0)$(tput setaf 15)"
  qrencode "pkg upgrade ; pkg install $T_BUF4 && if ! pidof $T_BUF6 > /dev/null;then eval \"$T_BUF5\";fi" -t UTF8
  echo "Enter for next"; read T_BUF
  qrencode "$(echo "U=$1;$T_CMD > gki.sh && sh gki.sh \$U" | sed 's/\\/\\\\/')" -t UTF8
  echo -n "$(tput sgr0)"
}
