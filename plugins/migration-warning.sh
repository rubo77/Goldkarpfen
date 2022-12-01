#GPL-3 - See LICENSE file for copyright and license details.
__MIGRATION(){
  T_BUF1=$OWN_ADDR
  T_BUF2=$(./keys.sh .keys/pub.pem 2> /dev/null)
  if ! test "$T_BUF2" = "$T_BUF1" && test "${T_BUF2#0}" = "${T_BUF1#1}";then
    echo; echo "Warning: you are using a deprecated key_addr - the support for it will end at some point." | ag "."
    cat DOC/address_migration.txt
  fi
  if test -f check-dependencies-ubuntu.sh;then echo "  II check-dependencies-ubuntu.sh is deprecated, you can delete it";fi
}

USER_HOOK_START="__MIGRATION ; $USER_HOOK_START"
