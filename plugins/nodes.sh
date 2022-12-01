#GPL-3 - See LICENSE file for copyright and license details.
USER_PLUGINS_MENU="[a]-add_stream_url:__USER_ADD $USER_PLUGINS_MENU"
__USER_ADD(){
  if test "$ITPFILE" = "$OWN_STREAM";then echo "  II do not add your own url - abort";return;fi
  if head -n 1 "$ITPFILE" | ag '^#ITP <url1=(\bhttp\b|\bgopher\b)' | ag '://[0-9A-Za-z]{1,80}\..*>' > /dev/null;then
    T_BUF=$(head -n 1 "$ITPFILE" | sed 's/^.*<url1=//' |sed 's/>.*$//')
    if grep "$T_BUF" nodes.dat;then
      echo "  II this url is already in your node list"
    else
      echo "  ?? are you sure to add $T_BUF to nodes.dat (y/n) >"
      $GK_READ_CMD T_CONFIRM
      if test "$T_CONFIRM" != "y";then return;fi
      echo $T_BUF >> nodes.dat
    fi
  else
    echo "  II this itp file has no url tag"
  fi
  return
}

if echo "$GK_MODE" | ag "tor|i2p" > /dev/null;then
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
      echo; sed -i "1s%^#ITP%#ITP <url1=$T_BUF>%" $OWN_STREAM
      __OWN_SHA_SUM_UPDATE
    fi
    return
  }
fi

USER_PLUGINS_MENU="[A]-sync_all:__USER_SYNC_ALL $USER_PLUGINS_MENU"
__USER_SYNC_ALL(){
  printf "  II it may be more convenient to open another terminal and use: ./sync-from-nodes.sh --loop\n  ?? proceed? (y/n) >"
  $GK_READ_CMD T_BUF; echo
  if test "$T_BUF" != "y";then return;fi
  if test -f my-sync-from-nodes.sh;then ./my-sync-from-nodes.sh;else ./sync-from-nodes.sh;fi
}
