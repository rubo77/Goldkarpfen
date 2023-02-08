#GPL-3 - See LICENSE file for copyright and license details.
USER_PLUGINS_MENU="[U]-update_Goldkarpfen:__USER_UPDATE $USER_PLUGINS_MENU"
__USER_UPDATE(){
  cd update || exit
  echo "  ## FIRST RUN"
  if ./sync_runtime_files.sh --first-run;then
    sync
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
    if ! echo "$T_BUF3" | ag "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$" > /dev/null;then echo "  EE input error";return;fi
    set -- "$T_BUF3:$(sed -n '4 p' Goldkarpfen.config)"
    T_BUF1=;T_BUF4="curl tor";T_BUF5="tor --quiet &";T_BUF6="tor"
  else
    set -- $(head -n 1 "$OWN_STREAM" | ag -o "<url1=http://[A-Za-z0-9.]*.onion|<url1=http://[A-Za-z0-9.]*.i2p>")
    if test -z "$1";then echo "  EE your url1 header tag is not valid";echo "  II p2p-installer only for tor/i2p";return;fi
    set -- "${1#<url1=}"; set -- "${1%>}"
    if echo "$1" | ag "\.i2p$" > /dev/null;then T_BUF1="--proxy localhost:4444";T_BUF4="curl i2pd";T_BUF5="i2pd --daemon --loglevel=none &";T_BUF6="i2pd";else T_BUF1="--proxy socks5://127.0.0.1:9050 --socks5-hostname 127.0.0.1:9050";T_BUF4="curl tor";T_BUF5="tor --quiet &";T_BUF6="tor";fi
    set -- "${1#<url1=http://}"; set -- "${1%>}"
  fi
  qrencode "pkg upgrade ; pkg install $T_BUF4 && if ! pidof $T_BUF6 > /dev/null;then eval \"$T_BUF5\";fi" -t UTF8
  echo "Enter for next"; read T_BUF
  qrencode "U=$1;curl -f $T_BUF1 \$U/share/gki.sh > gki.sh && sh gki.sh \$U" -t UTF8
}
