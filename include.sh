#GPL-3 - See LICENSE file for copyright and license details.
T_BUF=$(sed -n '6p' Goldkarpfen.config); if test "$T_BUF" = "$(printf "%i" "$T_BUF" 2> /dev/null)";then GK_TOR_PORT="$T_BUF";else GK_TOR_PORT="9050";fi
split() {
    set -f
    old_ifs=$IFS
    IFS=$2
    set -- $1
    printf '%s\n' "$@"
    IFS=$old_ifs
    set +f
}

__collum(){
  arg1=$1;old_ifs=$IFS
  if test $# -gt 1;then IFS=$2;fi
  while read -r T_LINE; do
    set -- $T_LINE
    for I in $(split "$arg1" "-");do
      col=$I
      eval "echo -n \${${col}}"
    done
    echo
  done
  IFS=$old_ifs
}

basename() {
    # Usage: basename "path" ["suffix"]
    dir=${1%${1##*[!/]}}
    dir=${dir##*/}
    dir=${dir%"$2"}
    printf '%s\n' "${dir:-/}"
}

pipe_if_not_empty () {
  head=$(dd bs=1 count=1 2>/dev/null; echo a)
  head=${head%a}
  if [ "x$head" != x"" ]; then
    { printf %s "$head"; cat; } | "$@"
  fi
}

__DOWNLOAD_COMMAND () {
  if echo "$1" | ag "^gopher://" > /dev/null;then THE_CHAR_OF_TERROR='\/';else THE_CHAR_OF_TERROR='';fi
  if echo "$1" | ag "^.*\.i2p" > /dev/null;then
    echo "curl --progress-bar -f --proxy localhost:4444 $1""/""$THE_CHAR_OF_TERROR""$2"
  elif echo "$1" | ag "\d{1,3}.\d{1,3}.\d{1,3}\.\d{1,3}|localhost" > /dev/null;then
    echo "curl --progress-bar -f $1""/""$THE_CHAR_OF_TERROR""$2"
  else
    echo "curl --progress-bar -f --proxy socks5://127.0.0.1:$GK_TOR_PORT --socks5-hostname 127.0.0.1:$GK_TOR_PORT $1""/""$THE_CHAR_OF_TERROR""$2"
  fi
}

__ARCHIVE_DATE(){
  TZ=UTC tar -tvf "$1" | head -n 1 | __collum 4 | ag -o "\d\d-\d\d-\d\d"
}

__TEST_ARCHIVE_CONTENT(){
  if ! test $(tar -tvf "$1" | ag " $(basename "$1" | __collum 1 ".").itp$| $(basename "$1" | __collum 1 ".").itp.sha512sum$| $(basename "$1" | __collum 1 ".").itp.sha512sum.sig$" | wc -l) = 3;then
    >&2 echo "  EE $1 does not contain the required file set - moved to quarantine for inspection"
    mv "$1" "$(mktemp -p quarantine "GARBAGE_$(basename "$1")${2#*//}.XXXXXXXX")" || exit
    return 1
  fi
}

__TEST_AND_UNPACK_ARCHIVE(){
  if test "$1" = "--no-unpack";then T_BUF1="--no-unpack";shift;fi
  __TEST_ARCHIVE_CONTENT "$1" "$2"|| return 1
  tar -xf "$1" -C tmp/ > /dev/null || return 1
  # FILENAME TMP_FILENAME OPTION_NO_UNPACK
  set -- "$1" "tmp/$(basename "${1%.gz}")" "$2"
  set -- "$1" "${2%.tar}" "$3"
  T_BUF=$(tail -n 1 "$2" | ag "^#LICENSE:CC0 \d\d-\d\d-\d\d$" | __collum 2)
  if ! test "$T_BUF" = "$(__ARCHIVE_DATE "$1")";then
    echo "  EE $1 time stamp is not valid - moved to quarantine for inspection"
    rm -f "$2.sha512sum" "$2.sha512sum.sig" "$2"
    mv "$1" "$(mktemp -p quarantine "GARBAGE_$(basename "$1").XXXXXXXX")" || exit
    return 1
  fi
  if ./itp-check.sh "$2" "$2.sha512sum" && ./check-sign.sh "$2" > /dev/null 2>&1;then
    if ! test "$T_BUF1" = "--no-unpack";then
      mv "$2.sha512sum" itp-files && mv "$2.sha512sum.sig" itp-files && mv "$2" itp-files || exit
    else
      rm -f "$2" "$2.sha512sum" "$2.sha512sum.sig"
    fi
  else
    echo "  EE $1 no valid signature or/and itp-check failed - moved to quarantine for inspection"
    rm -f "$2.sha512sum" "$2.sha512sum.sig" "$2"
    mv "$1" "$(mktemp -p quarantine "GARBAGE_$(basename "$1")${3#*//}.XXXXXXXX")" || exit
    return 1
  fi
}

__TEST_ALIAS_FILE(){
  if ! test "$(__collum 1 < "$1" | sort | uniq | wc -l)" = "$(__collum 1 < "$1" | wc -l)";then
    printf "\n  II WARNING: you have double aliases - pls run [y][y] after initialization\n"; return 1
  fi
}

__PRUNE_ARCHIVES(){
  set -- "$(__collum 2 < archives/server.dat | sort -t "-" -k1n -k2n -k3n | head -n 1)"
  if test -z "$1" || ./check-dates.sh "$1" 2> /dev/null;then return;fi
  printf "\n  II OLD ARCHIVES NEED PRUNING!\n"
  mkdir -p quarantine/old-archives || exit
  while IFS= read -r T_LINE; do
    set -- $T_LINE
    if ! ./check-dates.sh "$2";then
      echo "  EE archives/$1 is too old - moved to quarantine/old-archives" | ag "."
      mv "archives/$1" "quarantine/old-archives/$2-$1" || exit
      if test -f "archives/$1_$3"; then mv "archives/$1_$3" "quarantine/old-archives/$2-$1_$3";fi
      ./update-archive-date.sh "$1" || exit
    fi
  done < archives/server.dat
}

__REMOVE_IF_MISSING(){
  while IFS= read -r T_FILE;do
    if ! test -f "$T_FILE";then
      echo "  II $T_FILE is missing but in the sane list - removing cached files" | ag "."
      BN=$(basename "$T_FILE")
      rm -f "$T_FILE.sha512sum" "$T_FILE.sha512sum.sig" "cache/$BN.sha512sum"
      sed -i "/$BN/d" cache/sane_files cache/aliases || exit
    fi
  done < cache/sane_files
}

__INIT_FILES(){
  __REMOVE_IF_MISSING
  for T_FILE in itp-files/*.itp;do
    # CACHE_SUM_FILE
    set -- "cache/"$(basename "$T_FILE")".sha512sum"
    if ! test -f "$T_FILE.sha512sum";then echo "  EE $T_FILE has no SUM_FILE - fix this first";exit;fi
    if ! test -f "$1" || test $(sha512sum "$T_FILE" | __collum 1) != $(__collum 1 < "$1");then
      echo "  ## sanity_check $T_FILE"
      if ! ./check-sign.sh "$T_FILE" > /dev/null 2>&1;then
        echo "  EE $T_FILE signature ERROR" | ag "."
        printf "  II this should normally not happen, as the signatures get checked before\n  II is this your own file ? you find the backup files in bkp/\n"
        if test "$T_FILE" = "$OWN_STREAM";then exit
        else
          for T_BUF in "$T_FILE" "$T_FILE.sha512sum" "$T_FILE.sha512sum.sig";do mv "$T_BUF" "$(mktemp -p quarantine "GARBAGE_$(basename "$T_BUF").XXXXXXXX")" || exit;done
          __REMOVE_IF_MISSING;
        fi
      elif ./itp-check.sh "$T_FILE" "$T_FILE.sha512sum";then
        if ! test -f "$1";then
          if ! ag $(basename "$T_FILE") cache/aliases > /dev/null 2>&1;then
            T_BUF=$(basename "$T_FILE" | __collum 1 "-" )
            echo "$T_BUF "$(basename "$T_FILE") >> cache/aliases || exit
          fi
        fi
        if ! ag "^$T_FILE$" cache/sane_files > /dev/null; then echo "$T_FILE" >> cache/sane_files;fi
        T_BUF=$(basename "$T_FILE")
        if ! ag "$T_BUF" cache/aliases > /dev/null;then echo $(echo "$T_BUF"| __collum 1 "-")" $T_BUF" >> cache/aliases;fi
        cp "$T_FILE.sha512sum" cache || exit
      else
        T_BUF=$(basename "$T_FILE")
        sed -i "/$T_BUF/d" cache/sane_files cache/aliases || exit
        echo "  EE $T_FILE is not itp-conform: remove it from ./itp-files/"
      fi
    fi
  done
  __TEST_ALIAS_FILE cache/aliases
}
