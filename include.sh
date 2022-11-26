#GPL-3 - See LICENSE file for copyright and license details.
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
  arg1=$1
  if test $# -gt 1;then old_ifs=$IFS; IFS="$2";fi
  while read T_LINE; do
    set -- $T_LINE
    for I in $(split "$arg1" "-");do
      col=$I
      eval "echo -n \${${col}}"
    done
    echo
  done < /dev/stdin
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
  elif echo "$1" | ag "(\b127.0.0.1\b|\blocalhost\b)" > /dev/null;then
    echo "curl --progress-bar -f $1""/""$THE_CHAR_OF_TERROR""$2"
  else
    echo "curl --progress-bar -f --proxy socks5://127.0.0.1:9050 --socks5-hostname 127.0.0.1:9050 $1""/""$THE_CHAR_OF_TERROR""$2"
  fi
}

__ARCHIVE_DATE(){
  date --utc "+%y-%m-%d" -d $(tar -tvf "$1" --utc | head -n 1 | __collum 4)
}

__TEST_ARCHIVE_CONTENT(){
  if ! test $(tar -tvf "$1" | ag " $(basename $1 | __collum 1 ".").itp$| $(basename $1 | __collum 1 ".").itp.sha512sum$| $(basename $1 | __collum 1 ".").itp.sha512sum.sig$" | wc -l) = 3;then
    >&2 echo "  EE $1 does not contain the required file set - moved to quarantine for inspection"
    mv "$1" quarantine/"GARBAGE_$(basename $1).$(mktemp -u XXXXXXXX)"
    return 1
  fi
}

__TEST_ARCHIVE_DATE(){
  T_BUF1=$(__ARCHIVE_DATE $1)
  if ! ./check-dates.sh "$T_BUF1";then return 1;fi
  if ! test -z "$2";then
    T_BUF2=$(__ARCHIVE_DATE $2)
  else
    T_BUF="itp-files/$(basename "$1" |sed 's/\.tar\.gz$//').sha512sum"
    if test -f "$T_BUF";then
      T_BUF2=$(TZ=UTC ls --full-time --time-style="+%y-%m-%d" "$T_BUF" | __collum 6)
    else
      return 0
    fi
  fi
  echo "  II tarball: $T_BUF1"
  echo "  II local  : $T_BUF2"
  if ! ./check-dates.sh "$T_BUF1" "$T_BUF2";then return 1;fi
}

__TEST_AND_UNPACK_ARCHIVE(){
  if ! __TEST_ARCHIVE_CONTENT $1;then return 1;fi
  tar xfv "$1" -C tmp/ > /dev/null
  # FILENAME TMP_FILENAME OPTION_NO_UNPACK
  set "$1" "tmp/$(basename "${1%.tar.gz}")" "$2"
  T_BUF=$(tail -n 1 $2 | ag "^#LICENSE:CC0 \d\d-\d\d-\d\d$" | awk '{print $2}')
  if ! test "$T_BUF" = "$(date --utc +%y-%m-%d -d $(TZ="UTC" ls -l --time-style="long-iso"  $2 | __collum 6))";then
    echo "  EE $1 time stamp is not valid - moved to quarantine for inspection"
    rm "$2.sha512sum" "$2.sha512sum.sig" "$2"
    mv "$1" quarantine/"GARBAGE_$(basename $1).$(mktemp -u XXXXXXXX)"
    return 1
  fi
  if ./itp-check.sh "$2" "$2"".sha512sum" && ./check-sign.sh "$2" > /dev/null 2>&1;then
    if ! test "$3" = "--no-unpack";then
      mv "$2.sha512sum" itp-files
      mv "$2.sha512sum.sig" itp-files
      mv "$2" itp-files
    else
      rm "$2" "$2.sha512sum" "$2.sha512sum.sig"
    fi
  else
    echo "  EE $1 no valid signature or/and itp-check failed - moved to quarantine for inspection"
    rm "$2.sha512sum" "$2.sha512sum.sig" "$2"
    mv "$1" quarantine/"GARBAGE_$(basename $1).$(mktemp -u XXXXXXXX)"
    return 1
  fi
}

__TEST_ALIAS_FILE(){
  if ! test "$(__collum 1 < "$1" | sort | uniq | wc -l)" = "$(__collum 1 < "$1" | wc -l)";then
    printf "\n  II WARNING: you have double aliases - pls run [y][y] after initialization\n"; return 1
  fi
}

__PRUNE_ARCHIVES(){
  set "$(__collum 2 < archives/server.dat | sort -t "-" -k1n -k2n -k3n | head -n 1)"
  if test -z "$1" || ./check-dates.sh "$1";then return;fi
  printf "\n  II OLD ARCHIVES NEED PRUNING!\n"
  mkdir -p quarantine/old-archives
  while IFS= read -r T_LINE; do
    set $T_LINE
    if ! ./check-dates.sh $2;then
      echo "  EE archives/$1 is too old - moved to quarantine/old-archives" | ag "."
      mv "archives/$1" "quarantine/old-archives/$2-$1"
      if test -f "archives/$1_$3"; then mv "archives/$1_$3" "quarantine/old-archives/$2-$1_$3";fi
      sed -i "/$T_LINE/d" archives/server.dat
    fi
  done < archives/server.dat
  ./update-archive-date.sh
}

__REMOVE_IF_MISSING(){
  while IFS= read -r T_FILE;do
    if ! test -f "$T_FILE";then
      echo "  II $T_FILE is missing but in the sane list - removing cached files" | ag "."
      BN=$(basename "$T_FILE")
      rm -f "$T_FILE.sha512sum" "$T_FILE.sha512sum.sig" "cache/$BN.sha512sum"
      sed -i "/$BN/d" cache/sane_files cache/aliases
    fi
  done < cache/sane_files
}

__INIT_FILES(){
  __REMOVE_IF_MISSING
  for T_FILE in itp-files/*.itp;do
    # CACHE_SUM_FILE
    set "cache/"$(basename "$T_FILE")".sha512sum"
    if ! test -f "$T_FILE"".sha512sum";then echo "  EE $T_FILE has no SUM_FILE - fix this first";exit;fi
    if ! test -f "$1" || test $(sha512sum "$T_FILE" | __collum 1) != $(__collum 1 < "$1");then
      echo "  ## sanity_check $T_FILE"
      if ! ./check-sign.sh "$T_FILE" > /dev/null 2>&1;then
        echo "  EE $T_FILE signature ERROR" | ag "."
        printf "  II this should normally not happen, as the signatures get checked before\n  II is this your own file ? you find the backup files in bkp/\n"
        exit
      fi
      if ./itp-check.sh "$T_FILE" "$T_FILE"".sha512sum";then
        if ! test -f "$1";then
          if ! ag $(basename "$T_FILE") cache/aliases > /dev/null 2>&1;then
            T_BUF=$(basename "$T_FILE" | __collum 1 "-" )
            echo "$T_BUF "$(basename "$T_FILE") >> cache/aliases
          fi
        fi
        if ! ag "^$T_FILE$" cache/sane_files > /dev/null; then echo "$T_FILE" >> cache/sane_files;fi
        T_BUF=$(basename "$T_FILE")
        if ! ag "$T_BUF" cache/aliases > /dev/null;then echo $(echo "$T_BUF"| __collum 1 "-")" $T_BUF" >> cache/aliases;fi
        cp $T_FILE".sha512sum" cache
      else
        T_BUF=$(basename "$T_FILE")
        sed -i "/$T_BUF/d" cache/sane_files cache/aliases
        echo "  EE $T_FILE is not itp-conform: remove it from ./itp-files/"
      fi
    fi
  done
  __TEST_ALIAS_FILE cache/aliases
}
