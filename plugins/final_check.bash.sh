#GPL-3 - See LICENSE file for copyright and license details.
#V0.9
#GKdev-1FHDi5veznUojyHaZQ9wv5dwj5aqZmXYGg.itp

USER_PLUGINS_MENU="[C]-compare:__USER_COMPARE $USER_PLUGINS_MENU"
__USER_COMPARE(){
  set -- "$(diff --help 2>&1 | ag -o -- "--color" | tail -n 1 )"; test -z "$1" || set -- "$1=always"
  T_FILE=$(find archives/ -name "$OWN_ALIAS-$OWN_ADDR.itp.tar.gz")
  if test -z "$T_FILE"; then echo "  II no local archive found";return;fi
  echo "  ## DIFF (ITP <-> ARCHIVE) BEGIN"
  bash -c "diff "$1" <(tar -xOf $T_FILE "$OWN_ALIAS-$OWN_ADDR.itp") <(< $OWN_STREAM)"
  echo "  ## DIFF (ITP <-> ARCHIVE) END"
}

__USER_FCHECK(){
  T_FILE=$(find archives/ -name "$OWN_ALIAS-$OWN_ADDR.itp.tar.gz")
  if test -z "$T_FILE"; then return;fi
  __USER_COMPARE
  set -- "$(date --utc -d "$(TZ=UTC tar -tvf "archives/$OWN_ALIAS-$OWN_ADDR.itp.tar.gz" "$OWN_ALIAS-$OWN_ADDR.itp.sha512sum" | __collum 4)" +"%y-%m-%d")"
  if test "$1" = "$(date --utc '+%y-%m-%d')";then echo "  II YOU HAVE ALREADY ARCHIVED TODAY";fi
  printf "  ?? really archive? Y/[N] >"
  $GK_READ_CMD T_CONFIRM
  if ! test "$T_CONFIRM" = "Y";then echo; return 1;fi
}

USER_HOOK_ARCHIVE_START="__USER_FCHECK && $USER_HOOK_ARCHIVE_START || return 1"
