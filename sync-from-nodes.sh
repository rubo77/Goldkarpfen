#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
if ! test -f $(basename "$0");then echo "  EE run this script in its folder";exit 1;fi
if test -f cache/sync-from-nodes.pid && ps ax | ag "^ *$(cat cache/sync-from-nodes.pid) " > /dev/null;then echo "  EE sync-from-nodes.pid exists";exit 0;fi
echo $$ > cache/sync-from-nodes.pid

__CHECK_FOR_UPD(){
  __INIT_FILES
  for T_FILE in $(ls sync/ | ag "^($UPD_NAME_REGEXP)$");do
    T_BUF=$(tar -xOf "sync/$T_FILE" Goldkarpfen/update-provider.inc.sh | ag -m 1 -o "[0-9A-Za-z_]{1,12}-[0-9A-Za-z]{34}\.itp" 2> /dev/null)
    VERSION_ARCHIVES=$(tar -tf "sync/$T_FILE" 2> /dev/null | ag "VERSION" | __collum 3 "." || echo 0)
    if test "$(ag -m 1 -o "$T_FILE VERSION-2\.1\.\d*" "itp-files/$T_BUF" 2> /dev/null | sed 's/.*\.//' )" = "$VERSION_ARCHIVES";then
      if ! ag " $(sha512sum sync/$T_FILE | __collum 1) " "itp-files/$T_BUF" > /dev/null;then
        printf "  EE Could not verify checksum of $T_FILE - moved to quarantine/GARBAGE\n"
        mv "sync/$T_FILE" "$(mktemp -p quarantine "GARBAGE_$T_FILE${URL#*//}.XXXXXXXX")" || exit 1
      else
        echo "  II $T_FILE verified"
        mv "sync/$T_FILE" archives/ && ./update-archive-date.sh "$T_FILE" || exit 1
      fi
    else
      echo "  II $T_FILE / $T_BUF version mismatch -> skip"
      rm -f "sync/$T_FILE"
    fi
  done
}

__UPD_NOTIFY(){
  VERSION_ARCHIVES=$(printf "%i" "$(tar -tf archives/"$UPD_NAME" 2> /dev/null | ag "VERSION" | __collum 3 ".")" 2> /dev/null)
  VERSION_LOCAL=$(ls VERSION-* | tail -n 1);VERSION_LOCAL=$(printf "%i" "${VERSION_LOCAL#VERSION-2.1.}")
  if test "$VERSION_ARCHIVES" -gt "$VERSION_LOCAL";then echo "  II NEW GOLDKARPFEN : 2.1.$VERSION_ARCHIVES -> UPDATE WITH [r][U] " | ag ".";fi
}

__DOWNLOAD(){
  if test -z "$UPDATE_ONLY";then
    if test $(ag --no-numbers --no-filename -v "^($UPD_NAME_REGEXP)|^($VERIFICATION_STREAM.tar.gz)" archives/server.dat | wc -l) -gt 49;then
      UPDATE_ONLY="y"; echo "  II archive-file-num-cap reached - UPDATE_ONLY mode" | ag "."
      if test "$2" = "--new";then return;fi
    fi
  fi
  echo "$(tput rev)$1$(tput sgr0)"
  T_CMD=$(__DOWNLOAD_COMMAND "$URL" "$1" || echo "__error_getting_dl_cmd;")
  $T_CMD -o "sync/$1" --max-filesize 318K || return 1
  if test "$2" = "--patch";then
    set -- "$(echo "$1" | __collum 1 ".").itp.tar" "$2" "$1"
    gunzip -c "archives/$1.gz" > tmp/tmp.tar; if ! xdelta3 -d -s tmp/tmp.tar "sync/$3" "sync/$1";then rm -f tmp/tmp.tar "sync/$3";return 1;else rm -f tmp/tmp.tar;fi
  fi
  if ! test "$(__ARCHIVE_DATE "sync/$1")" = "$FILE_DATE";then
    if test "$2" = "--patch";then rm -f "sync/$3" "sync/$1" || exit 1;else
      printf "  EE age difference : server.dat <-> archive - skip\n"
      rm -f "sync/$1" || exit 1
    fi
    return 1
  fi
  if echo "$1" | ag "$UPD_NAME_REGEXP" > /dev/null;then return 0;fi
  if ag "${1%.tar.gz}|${1%.tar}" cache/sane_files > /dev/null || test "$1" = "$VERIFICATION_STREAM.tar.gz";then
     T_TARGET="archives/" ; OPTIONS=
  elif test -f "archives/${1%.gz}.gz";then
     T_TARGET="archives/" ; OPTIONS="--no-unpack"
  else
     echo "  II NEW ARCHIVE - first unpack needs to be done manually"
     T_TARGET="quarantine/" ; OPTIONS="--no-unpack"
  fi
  if __TEST_AND_UNPACK_ARCHIVE $OPTIONS "sync/$1" "$URL";then
    if test "$2" = "--patch";then gzip "sync/$1" ; set -- "$1.gz" "$2" "$3" ; rm -f "archives/$1_D"* ; mv "sync/$3" archives/;else
    rm -f "archives/$1_D"*;fi
    mv "sync/$1" "$T_TARGET" || exit 1
  else
    if test -f "sync/$3";then rm -f "sync/$3" || exit 1;fi
    return 1
  fi
  ./update-archive-date.sh "$1" || exit 1
}

__SYNC_ALL(){
  grep -v "^[[:blank:]]*#" < nodes.dat | ag "$T_PATTERN" |
  while IFS= read -r NODE; do
    if test -z "$NODE";then echo "  II got empty line - break";break;fi
    URL=$(echo "$NODE" | __collum 1)
    echo "$(tput rev)$URL$(tput sgr0)"
    T_CMD=$(__DOWNLOAD_COMMAND "$URL" "server.dat" || echo "__error_getting_dl_cmd;")
    SERVER_DAT="$($T_CMD --max-filesize 6K | ag "^[0-9A-Za-z_]{1,12}-[0-9A-Za-z]{34}\.itp\.tar\.gz \d\d-\d\d-\d\d( D\d\d-\d\d-\d\d$|$)|^($UPD_NAME_REGEXP) \d\d-\d\d-\d\d$" | grep $LIST_MODE -f "$LIST_RGXP" | sort -r | tr '\n' '\\' | sed 's/%/%%/g' | sed 's/\\/\\n/g')"
    if ! test -z "$SERVER_DAT";then
      sed -i "s@^$URL.*@$URL last_success:$(date +"%y-%m-%d")@" nodes.dat
      printf "$SERVER_DAT" | grep -v -F -f archives/server.dat |
      while IFS= read -r LINE; do
        #FILE DATE DIFF-DATE
        set -- $LINE ; FILE_DATE=$2
        LOCAL_DATE=$(ag -m 1 --no-numbers --no-filename  "^$1 " archives/server.dat 2> /dev/null | __collum 2)
        if ./check-dates.sh "$2" "$LOCAL_DATE" > /dev/null 2>&1;then
          if ! test "$1" = "$VERIFICATION_STREAM.tar.gz" && test -f "quarantine/$1" || test "$(ls "quarantine/GARBAGE_$1${URL#*//}."???????? 2> /dev/null | wc -l)" -gt 2;then
            echo "  II QUARANTINE : ${1%%-*1*} (skip)"
          elif ag "^$1 " archives/server.dat > /dev/null || test "$1" = "$UPD_NAME" || test "$1" = "$VERIFICATION_STREAM.tar.gz";then
            if test "$LOCAL_DATE" = "${3#D}" && test "$GK_DIFF_MODE" = "yes" && ! test "$1" = "$UPD_NAME" && ! test "$1" = "$VERIFICATION_STREAM.tar.gz";then
                if ! __DOWNLOAD "$1_$3" --patch;then __DOWNLOAD "$1";fi
              else
                __DOWNLOAD "$1"
            fi
          else
            if test -z "$UPDATE_ONLY";then __DOWNLOAD "$1" --new;fi
          fi
        fi
      done
      __CHECK_FOR_UPD
    fi
  done
  if ! test "$(ag --nonumbers "^[a-z]{3,6}://[A-Za-z0-9.]*[.:][A-Za-z0-9]{1,5} last_success:$(date +%y-%m-%d)" nodes.dat)" = "$(cat archives/tracker.dat)";then
    ag --nonumbers "^[a-z]{3,6}://[A-Za-z0-9.]*[.:][A-Za-z0-9]{1,5} last_success:$(date +%y-%m-%d)" nodes.dat > tmp/tracker.dat
    mv tmp/tracker.dat archives/ || exit 1
  fi
}

for T_ARG in $@;do
  if test "$T_ARG" = "--loop";then T_LOOP="yes"; shift
  elif echo "$T_ARG" | ag "^--pause=[0-9]*$" > /dev/null;then T_PAUSE="$(printf "%i" ${T_ARG#--pause=})"; shift
  elif echo "$T_ARG" | ag "^--pattern=.*$" > /dev/null;then T_PATTERN=${T_ARG#--pattern=}; shift
  else echo "usage : ./sync-from-nodes.sh [--loop] [--pattern=regexp] [--pause=seconds] # seconds>599";exit;fi
  if test -z "$T_PAUSE" || test "$T_PAUSE" -lt 600;then T_PAUSE=3600;fi
done
if test -z "$T_PATTERN";then T_PATTERN="^[a-z]{3,6}://[A-Za-z0-9.]*[.:][A-Za-z0-9]{1,5}|^$";fi
. ./update-provider.inc.sh && . ./include.sh || exit 1
if test -r ./my-include.sh;then . ./my-include.sh || exit;fi
if test -r ./whitelist.dat;then LIST_MODE=; LIST_RGXP="whitelist.dat";else LIST_MODE="-v"; LIST_RGXP="blacklist.dat";fi
if command -v xdelta3 > /dev/null 2>&1;then GK_DIFF_MODE="yes";fi
touch -a blacklist.dat archives/tracker.dat && mkdir -p cache/last_prune archives plugins quarantine sync bkp tmp || exit 1
trap 'echo "  ## pls wait ...";__CHECK_FOR_UPD;__UPD_NOTIFY; rm -f tmp/tmp.tar tmp/tracker.dat cache/sync-from-nodes.pid; trap - EXIT; exit 0' INT HUP TERM QUIT
trap 'echo "  ## pls wait ...";__CHECK_FOR_UPD;__UPD_NOTIFY; rm -f tmp/tmp.tar tmp/tracker.dat cache/sync-from-nodes.pid; trap - EXIT; exit' EXIT
./update-archive-date.sh || exit 1
if ! test -z "$LISTING_REGEXP";then UPD_NAME_REGEXP=$LISTING_REGEXP;fi
if test "$T_LOOP" = "yes";then
  while true;do
    __SYNC_ALL
    echo "  ## idle for $T_PAUSE - exit with ^C (-> ONCE <-)"
    sleep "$T_PAUSE"
  done
else
  __SYNC_ALL
fi
