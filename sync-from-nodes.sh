#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
if ! test -f $(basename "$0");then echo "  EE run this script in its folder";exit 1;fi
if test -f ./sync-from-nodes.pid && ps --pid $(cat sync-from-nodes.pid) > /dev/null;then echo "  EE sync-from-nodes.pid exists";exit 0;fi
echo $$ > sync-from-nodes.pid

__CHECK_FOR_UPD(){
  __INIT_FILES
  if test -f "quarantine/$UPD_NAME";then
    VERSION_ARCHIVES=$(tar -tf quarantine/"$UPD_NAME" 2> /dev/null | ag "VERSION" | __collum 3 "." || echo 0)
    if test "$(grep "$UPD_NAME_REGEXP VERSION-2\.1\." itp-files/$VERIFICATION_STREAM | tail -n 1 | sed 's/.*\.//' )" = "$VERSION_ARCHIVES";then
      if ! grep "$(sha512sum quarantine/$UPD_NAME | __collum 1)" itp-files/$VERIFICATION_STREAM;then
        printf "  EE Could not verify checksum. Be sure to have the latest Goldkarpfen-1JULSJ5Nnba9So48zi21rpfTuZ3tqNRaFB.itp file\n  $UPD_NAME is in quarantine and further downloads of it are paused.\n  Sync again and test manually with:\n"
        echo 'grep $(sha512sum quarantine/'$UPD_NAME' | awk '"'{print \$1}'"') itp-files/'"$VERIFICATION_STREAM"
        printf "  II If that works, you can move quarantine/$UPD_NAME archives\n  If in doubt remove quarantine/$UPD_NAME and sync again.\n"
      else
        mv quarantine/"$UPD_NAME" archives/ && ./update-archive-date.sh "$UPD_NAME" || exit 1
      fi
    else
      rm -f quarantine/"$UPD_NAME"
    fi
  fi
}

__UPD_NOTIFY(){
  VERSION_ARCHIVES=$(printf "%i" "$(tar -tf archives/"$UPD_NAME" 2> /dev/null | ag "VERSION" | __collum 3 ".")")
  VERSION_LOCAL=$(ls VERSION-* | tail -n 1);VERSION_LOCAL=$(printf "%i" "${VERSION_LOCAL#VERSION-2.1.}")
  if test "$VERSION_ARCHIVES" -gt "$VERSION_LOCAL";then echo "  II NEW GOLDKARPFEN : 2.1.$VERSION_ARCHIVES -> UPDATE WITH [r][U] " | ag ".";fi
}

__DOWNLOAD(){
  if test -z "$UPDATE_ONLY";then
    if test $(ag --no-numbers --no-filename -v "^(\b$UPD_NAME_REGEXP\b|\b$VERIFICATION_STREAM.tar.gz\b)" archives/server.dat | wc -l) -gt 58;then
      UPDATE_ONLY="y"; echo "  II archive-file-num-cap reached - UPDATE_ONLY mode" | ag "."
      if test "$2" = "--new";then return;fi
    fi
  fi
  echo "$(tput rev)$1$(tput sgr0)"
  T_CMD=$(__DOWNLOAD_COMMAND "$URL" "$1" || echo "__error_getting_dl_cmd;")
  $T_CMD -o "sync/$1" --max-filesize 318K || return 1
  if test "$2" = "--patch";then
    set -- "$(echo "$1" | __collum 1 ".").itp.tar" "$2" "$1"
    gunzip -c "archives/$1.gz" > tmp/tmp.tar; bspatch tmp/tmp.tar "sync/$1" "sync/$3"; rm -f tmp/tmp.tar
  fi
  if ! test "$(__ARCHIVE_DATE "sync/$1")" = "$FILE_DATE";then
    if test "$2" = "--patch";then rm -f "sync/$3" "sync/$1" || exit 1;else
      printf "  EE There is a difference in the server.dat and the real age of the archive,\n  The archive is missing files or your server.dat is corrupt.\n  moving the archive to quarantine for inspection\n"
      mv "sync/$1" "$(mktemp -p quarantine "GARBAGE_$(basename "$1").XXXXXXXX")" || exit 1
    fi
    return 1
  fi
  if test "$1" = "$UPD_NAME";then mv "sync/$1" quarantine || exit 1;return 0;fi
  if ag "${1%.tar.gz}|${1%.tar}" cache/sane_files > /dev/null || test "$1" = "$VERIFICATION_STREAM.tar.gz";then
     T_TARGET="archives/" ; OPTIONS=
  elif test -f "archives/${1%.gz}.gz";then
     T_TARGET="archives/" ; OPTIONS="--no-unpack"
  else
     echo "  II NEW ARCHIVE - first unpack needs to be done manually"
     T_TARGET="quarantine/" ; OPTIONS="--no-unpack"
  fi
  if __TEST_AND_UNPACK_ARCHIVE "sync/$1" $OPTIONS;then
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
  ag --no-numbers -v "^[[:blank:]]*#" < nodes.dat | ag "$T_PATTERN" |
  while IFS= read -r NODE; do
    if test -z "$NODE";then echo "  II got empty line - break";break;fi
    URL=$(echo "$NODE" | __collum 1)
    echo "$(tput rev)$URL$(tput sgr0)"
    T_CMD=$(__DOWNLOAD_COMMAND "$URL" "server.dat" || echo "__error_getting_dl_cmd;")
    SERVER_DAT="$($T_CMD --max-filesize 6K | ag "^[0-9A-Za-z_]{1,12}-[0-9A-Za-z]{34}\.itp\.tar\.gz \d\d-\d\d-\d\d( D\d\d-\d\d-\d\d$|$)|^$UPD_NAME_REGEXP \d\d-\d\d-\d\d$" | grep $LIST_MODE -f "$LIST_RGXP" | sort -R | tr '\n' '\\' | sed 's/%/%%/g' | sed 's/\\/\\n/g')"
    if ! test -z "$SERVER_DAT";then
      CH_LINE=$(grep -n "^$URL" nodes.dat | head -n 1 | __collum 1 ":")
      sed -i "$CH_LINE c$URL last_success:$(date +"%y-%m-%d")" nodes.dat
      printf "$SERVER_DAT" |
      while IFS= read -r LINE; do
        #FILE DATE DIFF-DATE
        set -- $LINE ; FILE_DATE=$2
        if ./check-dates.sh "$2" > /dev/null;then
          if ! test "$1" = "$VERIFICATION_STREAM.tar.gz" && test -f "quarantine/$1" || test "$(ls "quarantine/GARBAGE_$1."???????? 2> /dev/null | wc -l)" -gt 2;then
            echo "  II skip (quarantine/3XGarbage) : ${1%%-*1*}" | ag -v "^$UPD_NAME_REGEXP"
          elif ag "^$1 " archives/server.dat > /dev/null || test "$1" = "$UPD_NAME" || test "$1" = "$VERIFICATION_STREAM.tar.gz";then
            LOCAL_DATE=$(ag --no-numbers --no-filename  "^$1 " archives/server.dat | head -n 1 | __collum 2) ;
            if ./check-dates.sh "$2" "$LOCAL_DATE" > /dev/null 2>&1;then
              if test "$LOCAL_DATE" = "${3#D}" && test "$GK_DIFF_MODE" = "yes" && ! test "$1" = "$UPD_NAME" && ! test "$1" = "$VERIFICATION_STREAM.tar.gz";then
                  if ! __DOWNLOAD "$1_$3" --patch;then __DOWNLOAD "$1";fi
                else
                  __DOWNLOAD "$1"
              fi
            elif ! test "$LESS_VERBOSE" = "yes";then echo "  II no update : ${1%%-*1*}";fi
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
  elif test "$T_ARG" = "--less-verbose";then LESS_VERBOSE="yes"; shift
  elif echo "$T_ARG" | ag "^--pause=[0-9]*$" > /dev/null;then T_PAUSE="$(printf "%i" ${T_ARG#--pause=})"; shift
  elif echo "$T_ARG" | ag "^--pattern=.*$" > /dev/null;then T_PATTERN=${T_ARG#--pattern=}; shift
  else echo "usage : ./sync-from-nodes.sh [--less-verbose] [--loop] [--pattern=regexp] [--pause=seconds] # seconds>599";exit;fi
  if test -z "$T_PAUSE" || test "$T_PAUSE" -lt 600;then T_PAUSE=3600;fi
done
if test -z "$T_PATTERN";then T_PATTERN="^[a-z]{3,6}://[A-Za-z0-9.]*[.:][A-Za-z0-9]{1,5}";fi
. ./update-provider.inc.sh && . ./include.sh || exit 1
if test -f ./my-include.sh;then . ./my-include.sh || exit;fi
if test -f ./whitelist.dat;then LIST_MODE=; LIST_RGXP="whitelist.dat";else LIST_MODE="-v"; LIST_RGXP="blacklist.dat";fi
if command -v bspatch > /dev/null 2>&1;then GK_DIFF_MODE="yes";fi
touch -a blacklist.dat archives/tracker.dat && mkdir -p cache/last_prune archives plugins quarantine sync bkp tmp || exit 1
trap 'echo "  ## pls wait ...";__CHECK_FOR_UPD;__UPD_NOTIFY; rm -f tmp/tmp.tar tmp/tracker.dat sync-from-nodes.pid; trap - EXIT; exit 0' INT HUP TERM QUIT
trap 'echo "  ## pls wait ...";__CHECK_FOR_UPD;__UPD_NOTIFY; rm -f tmp/tmp.tar tmp/tracker.dat sync-from-nodes.pid; trap - EXIT; exit' EXIT
./update-archive-date.sh || exit 1

if test "$T_LOOP" = "yes";then
  while true;do
    __SYNC_ALL
    echo "  ## idle for $T_PAUSE - exit with ^C (-> ONCE <-)"
    sleep "$T_PAUSE"
  done
else
  __SYNC_ALL
fi
