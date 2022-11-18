#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
if ! test -f $(basename $0);then echo "  EE run this script in its folder";exit;fi
if test -f ./sync-from-nodes.pid && ps --pid $(cat sync-from-nodes.pid) > /dev/null;then echo "  EE sync-from-nodes.pid exists";exit;fi
echo $$ > sync-from-nodes.pid
. ./update-provider.inc.sh
. ./include.sh
if test -f ./whitelist.dat;then LIST_MODE=""; LIST_RGXP="whitelist.dat";else LIST_MODE="-v"; LIST_RGXP="blacklist.dat";fi

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
        mv quarantine/"$UPD_NAME" archives/
        ./update-archive-date.sh "$UPD_NAME"
      fi
    else
      rm quarantine/"$UPD_NAME"
    fi
  fi
}

__UPD_NOTIFY(){
  VERSION_ARCHIVES=$(printf "%i" "$(tar -tf archives/"$UPD_NAME" 2> /dev/null | ag "VERSION" | __collum 3 ".")")
  VERSION_LOCAL=$(ls VERSION-* | tail -n 1);VERSION_LOCAL=$(printf "%i" ${VERSION_LOCAL#VERSION-2.1.})
  if test "$VERSION_ARCHIVES" -gt "$VERSION_LOCAL";then echo "  II NEW GOLDKARPFEN : 2.1.$VERSION_ARCHIVES -> UPDATE WITH [r][U] " | ag ".";fi
}

trap 'echo "  ## pls wait ...";__CHECK_FOR_UPD;__UPD_NOTIFY; rm -f tmp/server.dat tmp/filtered_server.dat sync-from-nodes.pid; trap - EXIT; exit' EXIT INT HUP TERM QUIT

if which bspatch > /dev/null 2>&1;then GK_DIFF_MODE="yes";fi
touch -a blacklist.dat
touch -a archives/server.dat

__DOWNLOAD(){
  if test -z $UPDATE_ONLY;then
    if test $(ag --no-numbers --no-filename -v "^(\b$UPD_NAME_REGEXP\b|\b$VERIFICATION_STREAM.tar.gz\b)" archives/server.dat | wc -l) -gt 58;then
      UPDATE_ONLY="y"; echo "  II archive-file-num-cap reached - UPDATE_ONLY mode" | ag "."
      if test "$2" = "--new";then return;fi
    fi
  fi
  printf "\e[7m"$1"\e[0m\n"
  T_CMD=$(__DOWNLOAD_COMMAND "$URL" "$1" || echo "__error_getting_dl_cmd;")
  if $T_CMD -o "sync/$1" --max-filesize 318K;then
    #DIFF-PATCH-VERSION
    #if test "$2" = "--patch";then
    #  set "$(echo $1 | __collum 1 "_")" "$2" "$1"
    #  gunzip -c "archives/$1" > tmp/tmp.tar; bspatch tmp/tmp.tar "sync/${1%.gz}" "sync/$3"; gzip "sync/${1%.gz}" ; rm -f tmp/tmp.tar
    #fi
    if ! test "$(__ARCHIVE_DATE "sync/$1")" = "$FILE_DATE";then
      printf "  EE There is a difference in the server.dat and the real age of the archive,\n  The archive is missing files or your server.dat is corrupt.\n  moving the archive to quarantine for inspection\n"
      mv "sync/$1" quarantine/"$(basename $1)"".""$(mktemp -u XXXXXXXX)"
      #DIFF-PATCH-VERSION
      #if test -f "sync/$3";then mv "sync/$3" quarantine/"$(basename $3)"".""$(mktemp -u XXXXXXXX)";fi
      return 1
    fi
    if test "$1" = "$UPD_NAME";then mv "sync/$1" quarantine;return 0;fi
    if grep $(basename "${1%.tar.gz}") cache/sane_files || test "$1" = "$VERIFICATION_STREAM.tar.gz";then
       TARGET="archives/" ; OPTIONS=
    elif test -f "archives/$1";then
       TARGET="archives/" ; OPTIONS="--no-unpack"
    else
       echo "  II NEW ARCHIVE - first unpack needs to be done manually"
       TARGET="quarantine/" ; OPTIONS="--no-unpack"
    fi
    if __TEST_AND_UNPACK_ARCHIVE "sync/$1" $OPTIONS;then
      mv "sync/$1" $TARGET
      #DIFF-PATCH-VERSION
      #rm -f archives/$1_D*
      #if test -f "sync/$3";then mv "sync/$3" archives/;fi
    else
      #DIFF-PATCH-VERSION
      #if test -f "sync/$3";then mv "sync/$3" quarantine/"$(basename $3)"".""$(mktemp -u XXXXXXXX)";fi
      return 1
    fi
  fi
  ./update-archive-date.sh "$1"
}

__SYNC_ALL(){
  ag --no-numbers -v "^#" < nodes.dat |
  while IFS= read -r NODE; do
    if test -z "$NODE";then echo "  II got empty line - break";break;fi
    URL=$(echo "$NODE" | __collum 1)
    printf "\e[7m"$URL/server.dat"\e[0m\n"
    T_CMD=$(__DOWNLOAD_COMMAND "$URL" "server.dat" || echo "__error_getting_dl_cmd;")
    if $T_CMD -o tmp/server.dat --max-filesize 6K;then
      if file -b --mime-type tmp/server.dat | sed 's|/.*||' | ag -v "text";then echo "  EE fatal: server.dat is not a textfile";return 1;fi
      grep $LIST_MODE -f $LIST_RGXP < tmp/server.dat | ag "^[0-9A-Za-z_]{1,12}-[0-9A-Za-z]{34}\.itp\.tar\.gz \d\d-\d\d-\d\d( D\d\d-\d\d-\d\d$|$)|^$UPD_NAME_REGEXP \d\d-\d\d-\d\d$" | sort -R > tmp/filtered_server.dat
      CH_LINE=$(grep -n "^$URL" nodes.dat | head -n 1 | __collum 1 ":")
      sed -i "$CH_LINE c$URL last_success:$(date +"%y-%m-%d")" nodes.dat
      while IFS= read -r LINE; do
        #FILE DATE DIFF-DATE
        set $LINE ; FILE_DATE="$2"
        if ./check-dates.sh "$2" > /dev/null;then
          if ag "^$1 " archives/server.dat > /dev/null && ! test -f "quarantine/$1";then
            LOCAL_DATE=$(ag --no-numbers --no-filename  "^$1 " archives/server.dat | head -n 1 | __collum 2) ;
            if ./check-dates.sh "$2" "$LOCAL_DATE" > /dev/null 2>&1;then
              if test "$LOCAL_DATE" = "${3#D}" && test "$GK_DIFF_MODE" = "yes" && ! test "$FILE" = "$UPD_NAME" && ! test "$FILE" = "$VERIFICATION_STREAM.tar.gz";then
                  __DOWNLOAD "$1" #DIFF-PATCH-VERSION if ! __DOWNLOAD "$1_$3" --patch;then __DOWNLOAD "$1";fi
                else
                  __DOWNLOAD "$1"
              fi
            elif ! test "$LESS_VERBOSE" = "yes";then
              echo "  II no new version for $1"
            fi
          else
            if test -f "quarantine/$1";then
              if ! test "$LESS_VERBOSE" = "yes";then echo "  II $1 is quarantined - skipping download" | ag -v "^$UPD_NAME_REGEXP";fi
            elif test "$1" = "$UPD_NAME" || test "$1" = "$VERIFICATION_STREAM.tar.gz";then
              __DOWNLOAD "$1"
            elif test -z $UPDATE_ONLY;then
              __DOWNLOAD "$1" --new
            fi
          fi
        fi
      done < tmp/filtered_server.dat
      __CHECK_FOR_UPD
    fi
  done
}

./update-archive-date.sh
if test "$1" = "--loop";then
  shift
  if test "$1" = "--less-verbose";then LESS_VERBOSE="yes";shift;fi
  if test -z $1;then PAUSE=3600;else PAUSE="$1";shift;fi
  while true;do
    __SYNC_ALL
    echo "  ## idle for $PAUSE - exit with ^C (-> ONCE <-)"
    sleep $PAUSE
  done
else
  if test "$1" = "--less-verbose";then LESS_VERBOSE="yes";shift;fi
  __SYNC_ALL
fi
