#GPL-3 - See LICENSE file for copyright and license details.
__MIGRATION(){
  T_BUF1=$OWN_ADDR
  T_BUF2=$(./keys.sh .keys/pub.pem 2> /dev/null)
  if ! test "$T_BUF2" = "$T_BUF1" && test "$(echo $T_BUF1 |sed -e 's/^1*//')" = "$(echo $T_BUF2 |sed -e 's/^0*//' -e 's/^1*//')";then
    echo; echo "Warning: you are using a deprecated key_addr - the support for it has ended." | ag "."
    printf "\nold_KEY_ADDR : $T_BUF1\nnew_KEY_ADDR : $T_BUF2\nOWN_ALIAS    : $OWN_ALIAS\n\n"
    cat DOC/address_migration.txt ; exit
  fi
  if ! test "$(head -n 1 "$ITPFILE" | ag -o '<url1=(\bhttp://\b|\bgopher://\b).*>')" = "$(head -n 1 "$ITPFILE" | ag -o '<url1=.*>')";then
    echo "  II your url1 header tag has no protocol prefix (http:// or gopher://)" | ag .
  fi
  for T_FILE in $(ls check-dependencies-ubuntu.sh .Goldkarpfen.config.default.sh plugins/delete.sh plugins/add_node.sh plugins/download.sh 2> /dev/null);do
    echo "  II $T_FILE ist obsolete, you can delete it"
  done
}

USER_HOOK_START="__MIGRATION ; $USER_HOOK_START"
