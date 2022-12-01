#GPL-3 - See LICENSE file for copyright and license details.
#V0.1
#prt-01pJFCF3YGfyNgEDDNWHbBUMyeS2Rkgpux.itp

USER_PLUGINS_MENU="[C]-compare:__USER_COMPARE $USER_PLUGINS_MENU"
__USER_COMPARE(){
  T_FILE=$(find archives/ -name "$OWN_ALIAS-$OWN_ADDR.itp.tar.gz")
  echo "  ## DIFF (ITP <-> ARCHIVE) BEGIN"
  bash -c "diff <(tar xOf $T_FILE "$OWN_ALIAS-$OWN_ADDR.itp") <(cat $OWN_STREAM)"
  echo "  ## DIFF (ITP <-> ARCHIVE) END"
}

__USER_FCHECK(){
  __USER_COMPARE
  T_FILE=$(find archives/ -name "$OWN_ALIAS-$OWN_ADDR.itp.tar.gz")
  if test -z "$T_FILE"; then return;fi
  set  "$(date --utc -d "$(tar -tvf "archives/$OWN_ALIAS-$OWN_ADDR.itp.tar.gz" --utc "$OWN_ALIAS-$OWN_ADDR.itp.sha512sum" | __collum 4)" +"%y-%m-%d")"
  if test "$1" = "$(date --utc '+%y-%m-%d')";then echo "  II YOU HAVE ALREADY ARCHIVED TODAY";fi
  printf "  ?? really archive? (Y/n) >"
  $GK_READ_CMD T_CONFIRM
  if ! test "$T_CONFIRM" = "Y";then echo; return 1;fi
}

USER_HOOK_ARCHIVE_START="__USER_FCHECK && $USER_HOOK_ARCHIVE_START || return 1"
