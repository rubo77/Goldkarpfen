#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
if ! test -f $(basename "$0");then echo "  EE run this script in its folder";exit 1;fi
GK_PATH=$(pwd)

#help
if test "$1" = "-h" || test "$1" = "--help";then
  echo "  II USAGE: ./Goldkarpfen.sh" ; exit
fi

#test for dependencies
echo "  ## startup ..."
GK_MODE="ERROR"
if test -f my-check-dependencies.sh;then GK_MODE=$(./my-check-dependencies.sh | tail -n 1);else GK_MODE=$(./check-dependencies.sh | tail -n 1);fi
if test "$GK_MODE" = "ERROR";then exit;fi
if command -v bsdiff > /dev/null 2>&1; then GK_DIFF_MODE="yes";else echo "  II install bsdiff to enable diff-mode";fi

#new account?
if ! test -d .keys;then
  printf "  II FIRST START:\n./new-account\n./Goldkarpfen.sh\n" ; exit
fi

echo "  II setting MODE to: $GK_MODE"
#test if shell can read -n 1
if echo "a" | read -n 1 > /dev/null 2>&1;then GK_READ_CMD="read -n 1"; else GK_READ_CMD="read";fi

#run script on exit
trap "cd $GK_PATH;if __CONFIRM_EXIT; then . ./.Goldkarpfen.exit.sh; trap - EXIT; exit;fi" INT
trap "cd $GK_PATH;. ./.Goldkarpfen.exit.sh; trap - EXIT; exit" EXIT HUP TERM QUIT

#source include
. ./include.sh || exit
if test -f ./my-include.sh;then . ./my-include.sh || exit;fi

USER_HOOK_START="return"; USER_HOOK_ARCHIVE_START="return"

#functions
__CONFIRM_EXIT(){
  if test "$T_CHAR" = "Q";then return 0;fi
  printf "\n  II you pressed [CTRL][C] - ?? exit Goldkarpfen? y/[n] >"
  $GK_READ_CMD T_CONFIRM
  if test "$T_CONFIRM" != "y";then
    printf "\n  II exit aborted\n"
    T_CHAR=;T_CONFIRM=
    return 1
  fi
}

__CHECK_INPUT(){
  ag --no-numbers --no-color -v "^#" "$1" | tr '\n' ' ' | sed -e 's/\\/\&bsol;/g' -e 's/ *$//' > "$1-stripped" && mv "$1-stripped" "$1" || return 1
  if test $(wc -c < "$1") = 0;then echo "  EE input has 0 chars";return 1;fi
  if test $(wc -c < "$1") -gt "$2";then echo "  EE input has more than $2 chars";return 1;fi
  if test "$3" = "--post";then
    if ag "^\d\d\.\d\d:\d @" "$1" > /dev/null;then echo "  EE input is formated like a comment";return 1;fi
  fi
}

__COMMENT(){
  if test -z "$GK_JM";then echo "  EE no post selected";return;fi
  if ! date -d "20-$(echo "$GK_JM" | sed -e 's/\./-/' -e 's/:.*//')" > /dev/null;then echo "  EE invalid date - this may be just technical data";return 1;fi
  echo
  sed -n -e "$GK_LN p" "$ITPFILE" -e 's/\&bsol;/\\/g'
  printf "\n  ?? comment this post?  [c]-continue [a]-abort >"
  $GK_READ_CMD T_CONFIRM;if test "$T_CONFIRM" != "c";then printf "\n  II aborted\n";return;fi
  echo
  # PASTE_LINE TODAY
  set -- "$(ag "^#COMMENTS_END" "$OWN_STREAM"| __collum 1 ":")" "$(date --utc "+%m.%d")"
  # PASTE_LINE TODAY POST_NUMBER
  set -- "$1" "$2" "$(ag --no-numbers --no-color -B 1 "^#COMMENTS_END" "$OWN_STREAM" | ag "^$2" | sed 's/:/ /' | __collum 2)"
  if test -z "$3";then set -- "$1" "$2" 1; else set -- "$1" "$2" $(( $3 + 1 ));fi
  if test "$3" -gt 9;then echo "  EE you can only post 9 comments a day";return;fi
  echo "" > tmp/text; echo "#maximum: 971 chars ; lines with # in the beginnig get ignored ; newlines will replaced with spaces." >> tmp/text
  $EDITOR tmp/text
  if ! __CHECK_INPUT tmp/text 971;then echo "  EE input error";rm -f tmp/text;return;fi
  sed -i ""$1"i "$2":$3 $GK_JM @$GK_ID $(sed -n '1p' tmp/text)" "$OWN_STREAM"
  __OWN_SHA_SUM_UPDATE
  rm -f tmp/text
}

__SEARCH(){
  if test "$1" = "--comments";then
    # FUZZY_RESULT
    set -- "$( ag --no-numbers --no-filename "^\d\d\.\d\d:\d \d\d\.\d\d:\d @$GK_ID" itp-files/*.itp | sort -k1 -n -t ":" | sed -e 's/ @.................................. / /' -e 's/\&bsol;/\\/g' | pipe_if_not_empty $GK_FZF_CMD | __collum 2)"
  else
    # POST_BEGIN POST_END
    set -- "$(( $(ag "^#POSTS_BEGIN" "$ITPFILE"| __collum 1 ":") + 1 ))" "$(( $(ag "^#POSTS_END" "$ITPFILE"| __collum 1 ":") - 1 ))"
    # FUZZY_RESULT POST_BEGIN POST_END
    set -- "$(sed -n -e "$1 , $2 p" "$ITPFILE" -e 's/\&bsol;/\\/g' | ag "^\d\d.\d\d:\d " | pipe_if_not_empty $GK_FZF_CMD | __collum 1)" "$1" "$2"
  fi
  if test -z "$1";then return;fi
  # FUZZY_RESULT LINE
  set -- "$1" "$(grep -n "^$1 " "$ITPFILE" | head -n 1 | __collum 1 ":")"
  if test -z "$2";then return;fi
  GK_JM=$1; GK_LN=$2
}

__VIEW(){
  # BEGIN_LINE END_LINE TERM_COLLUMS
  set -- "$(( $(ag "^#POSTS_BEGIN" "$ITPFILE"| __collum 1 ":") + 1 ))" "$(( $(ag "^#POSTS_END" "$ITPFILE"| __collum 1 ":") - 1 ))"
  if test "$2" = 3;then echo "  II empty";return;fi
  if test -z "$GK_LN";then
    T_COUNTER=$2
  else
    T_COUNTER=$GK_LN
  fi
  printf "\n  $(tput bold)MM SUBMENU: viewer$(tput sgr0)  [t]-topic [/]-search_comments [n]-next [p]-previous [c]-comment [q]-exit_viewer\n" | fold -s -w "$GK_COLS"
  T_BUF=1
  while true;do
    if ! test $T_BUF = 0;then
      T_BUF1=$(sed -n "$T_COUNTER p" "$ITPFILE")
      T_BUF2=$(echo "$T_BUF1" | __collum 1)
      echo "* $T_BUF1" | sed 's/\&bsol;/\\/g' | fold -s -w "$GK_COLS"
      ag --no-numbers --no-heading "^\d\d\.\d\d:\d $T_BUF2 @$GK_ID" itp-files/*.itp | sort -k2 -n -t ":" |
      while IFS= read -r LLL;do
        T_BUF1=$(echo "$LLL" | __collum 2 "/" | __collum 1 ":" | __collum 1 "." | __collum 2 "-")
        T_BUF2=$(echo "$LLL" | __collum 2 ":" )
        echo "$LLL" | sed -e "s/^.*@.................................../$T_BUF2 \[$(ag --no-color --no-numbers $T_BUF1 cache/aliases | __collum 1)\] /" -e 's/\&bsol;/\\/g' | fold -s -w "$GK_COLS" | sed 's/^/    /'
      done
      if test "$T_COUNTER" = "$1";then printf "^^^^^";fi
      if test "$T_COUNTER" = "$2";then printf "_____";fi
      T_BUF=0
    fi
    GK_JM=$T_BUF2; GK_LN=$T_COUNTER
    $GK_READ_CMD T_CHAR ;printf "\r"
    case "$T_CHAR" in
      "") echo ;;
      n)
        if test "$T_COUNTER" -lt "$2";then
          T_COUNTER=$(( T_COUNTER + 1 ));T_BUF=1
        fi
      ;;
      p)
        if test "$T_COUNTER" -gt "$1";then
          T_COUNTER=$(( T_COUNTER - 1 ));T_BUF=1
        fi
      ;;
      t)
        __SEARCH
        T_COUNTER=$GK_LN;T_BUF=1
      ;;
      /)
        __SEARCH --comments
        T_COUNTER=$GK_LN;T_BUF=1
      ;;
      c)
        __COMMENT;T_BUF=1
        printf "\n  $(tput bold)MM SUBMENU: viewer$(tput sgr0)  [t]-topic [/]-search_comments [n]-next [p]-previous [c]-comment [q]-exit_viewer\n" | fold -s -w "$GK_COLS"
        ;;
      q) GK_LN=$T_COUNTER;break ;;
    esac
  done
}

__SELECT_STREAM(){
  if ! test -s ./cache/aliases;then printf "  EE you have no files to choose from - this can happen if you have non-conform itp files\n  II try rebuilding your aliases and rebuild all [y][y] [x][x]\n";return;fi
  set -- "$(__collum 1 < ./cache/aliases | pipe_if_not_empty $GK_FZF_CMD)"
  if test -z "$1" || ! ag "^$1" ./cache/aliases > /dev/null;then echo "  II empty";return;fi
  ITPFILE="itp-files/"$(ag --nonumbers --nocolor "^$1 " cache/aliases | head -n 1 | __collum 2)
  GK_JM=; GK_LN=
  __INIT_GLOBALS
}

__POST(){
  # PASTE_LINE TODAY
  set -- "$(ag "^#POSTS_END" "$OWN_STREAM" | __collum 1 ":")" "$(date --utc "+%m.%d")"
  # PASTE_LINE TODAY POST_NUMBER
  set -- "$1" "$2" "$(ag --no-numbers --no-color -B 1 "^#POSTS_END" "$OWN_STREAM" | ag "^$2" | sed 's/:/ /' | __collum 2)"
  if test -z "$3";then set -- "$1" "$2" 1; else set -- "$1" "$2" $(( $3 + 1 ));fi
  if test "$3" -gt 9;then echo "  EE you can only post 9 posts a day";return;fi
  echo "" > tmp/text; echo "#maximum: 1007 chars ; lines with # in the beginnig get ignored ; newlines will replaced with spaces." >> tmp/text
  $EDITOR tmp/text
  if ! __CHECK_INPUT tmp/text 1007 --post;then echo "  EE input error";rm -f tmp/text;return;fi
  echo "$2:""$3 $(sed -n '1p' tmp/text)" | sed 's/\&bsol;/\\/g'
  echo -n "  ?? add this post? [c]-continue [a]-abort >"
  $GK_READ_CMD T_CONFIRM;if test "$T_CONFIRM" != "c";then printf "\n  II aborted\n";rm -f tmp/text;return;fi
  echo
  sed -i ""$1"i "$2":$3 $(sed -n '1p' tmp/text)" "$OWN_STREAM"
  rm -f tmp/text
  if __OWN_SHA_SUM_UPDATE && test "$ITPFILE" = "$OWN_STREAM";then GK_JM="$2:$3"; GK_LN=$1;fi
}

__ARCHIVE(){
  if ! __HOOK_ARCHIVE_START;then return;fi
  if test -f "archives/$OWN_ALIAS-$OWN_ADDR.itp.tar.gz" && test "$(tar xOf "archives/$OWN_ALIAS-$OWN_ADDR.itp.tar.gz" "$OWN_ALIAS-$OWN_ADDR.itp.sha512sum")" = "$(cat "itp-files/$OWN_ALIAS-$OWN_ADDR.itp.sha512sum")";then
    echo "  II you haven’t changed anything - abort"; return
  fi
  sed -i "s/^#LICENSE:CC0.*$/#LICENSE:CC0 $(date --utc '+%y-%m-%d')/" "$OWN_STREAM"
  __OWN_SHA_SUM_UPDATE || return
  echo "  ## archiving"
  tar cfv "tmp/$OWN_ALIAS-$OWN_ADDR.itp.tar" --mtime="$(date +'%Y-%m-%d %H:00')" -C itp-files "$OWN_ALIAS-$OWN_ADDR.itp.sha512sum" "$OWN_ALIAS-$OWN_ADDR.itp" "$OWN_ALIAS-$OWN_ADDR.itp.sha512sum.sig" --utc --numeric-owner || return
  if test -f "archives/$OWN_ALIAS-$OWN_ADDR.itp.tar.gz";then
    if test -f "bkp/$OWN_ALIAS-$OWN_ADDR.itp.tar" && test "$GK_DIFF_MODE" = "yes";then
      set -- "$(__ARCHIVE_DATE "tmp/$OWN_ALIAS-$OWN_ADDR.itp.tar")" "$(__ARCHIVE_DATE "bkp/$OWN_ALIAS-$OWN_ADDR.itp.tar")"
      if ! test "$1" = "$2";then
        echo "  II generating diff from $2"
        bsdiff "bkp/$OWN_ALIAS-$OWN_ADDR.itp.tar" "tmp/$OWN_ALIAS-$OWN_ADDR.itp.tar" "tmp/$OWN_ALIAS-$OWN_ADDR.itp.tar.gz_D$2"
      fi
    fi
    rm -f "bkp/__$OWN_ALIAS-$OWN_ADDR.itp.tar" && cp "tmp/$OWN_ALIAS-$OWN_ADDR.itp.tar" bkp/ || exit
    set -- "$(__ARCHIVE_DATE "archives/$OWN_ALIAS-$OWN_ADDR.itp.tar.gz")" "$(__ARCHIVE_DATE "tmp/$OWN_ALIAS-$OWN_ADDR.itp.tar")" "$2"
    if test "$1" = "$2";then
      mv "bkp/$OWN_ALIAS-$OWN_ADDR.itp.tar" "bkp/__$OWN_ALIAS-$OWN_ADDR.itp.tar" && echo "  II rearchived - diff for $1 blocked" || exit
    fi
  fi
  gzip "tmp/$OWN_ALIAS-$OWN_ADDR.itp.tar" && mv "tmp/$OWN_ALIAS-$OWN_ADDR.itp.tar.gz" archives || return
  rm -f "archives/$OWN_ALIAS-$OWN_ADDR.itp.tar.gz_D"*
  if test -f "tmp/$OWN_ALIAS-$OWN_ADDR.itp.tar.gz_D$3";then mv "tmp/$OWN_ALIAS-$OWN_ADDR.itp.tar.gz_D$3" archives || exit;fi
  ./update-archive-date.sh "$OWN_ALIAS-$OWN_ADDR.itp.tar.gz" || exit
  test "$(du "archives/$OWN_ALIAS-$OWN_ADDR.itp.tar.gz" | __collum 1)" -lt "318" || echo "  II WARNING: your archive exeeds the size limit of 318kB " | ag "."
}

__TEST_ARCHIVE_DATE(){
  T_BUF1=$(__ARCHIVE_DATE "$1")
  ./check-dates.sh "$T_BUF1" || return 1
  T_BUF="itp-files/$(set -- "$(basename "$1")" ; echo "${1%.tar.gz}").sha512sum"
  if test -f "$T_BUF";then
    T_BUF2=$(TZ=UTC ls --full-time --time-style="+%y-%m-%d" "$T_BUF" | __collum 6)
  else
    return 0
  fi
  echo "  II tarball: $T_BUF1"
  echo "  II local  : $T_BUF2"
  ./check-dates.sh "$T_BUF1" "$T_BUF2" || return 1
}

__UNPACK(){
  set -- "$(ag --depth 0 -f -g "\.itp\.tar\.gz$" quarantine/ archives/ | pipe_if_not_empty $GK_FZF_CMD )"
  if test -z "$1" || ! test -f "$1";then echo "  II empty";return;fi
  if ! __TEST_ARCHIVE_DATE "$1";then
    echo -n "  ?? force unpack? Y/[N] >"
    $GK_READ_CMD T_CONFIRM;if test "$T_CONFIRM" != "Y";then printf "\n  II aborted\n";return;else echo;fi
  fi
  printf "  ## unpacking...\n"
  if ! __TEST_AND_UNPACK_ARCHIVE "$1";then ./update-archive-date.sh "$(basename "$1")" || exit;return;fi
  if echo "$1" | ag '^quarantine/' > /dev/null;then
    echo "  II first unpack of this itp-stream - review it first and then move it out of quarantine with [m]"
  fi
  __INIT_FILES
}

__MOVE_OUT_OF_QUARANTINE (){
  printf "\n  ## moving $1\n"
  rm -f "archives/$(basename $1)_"* && mv "$1" archives || exit
  ./update-archive-date.sh "$(basename "$1")" || exit
  __INIT_FILES
}

__DELETE_FROM_QUARANTINE (){
  printf "\n  ## removing $1\n"
  if test "$(basename "$ITPFILE")" = "$(basename "${1%.tar.gz}")";then ITPFILE=$OWN_STREAM; __INIT_GLOBALS;fi
  rm -f "$1" "itp-files/"$(basename "$1" | __collum 1 "." ).itp
  __INIT_FILES
  echo -n "  ?? add this stream to your blacklist? y/[n] >"
  $GK_READ_CMD T_CONFIRM;if test "$T_CONFIRM" != "y";then printf "\n  II blacklisting skipped\n";return;fi
  echo $(basename "$1") >> blacklist.dat && sort <  blacklist.dat | uniq > tmp/blacklist.dat && mv tmp/blacklist.dat ./blacklist.dat || exit
}

__QUARANTINE(){
  set -- "$(ag --depth 0 -f -g '[0-9A-Za-z_]{1,12}-[0-9A-Za-z]{34}\.itp\.tar\.gz$' quarantine/ | pipe_if_not_empty $GK_FZF_CMD)"
  if test -z "$1" || ! test -f "$1";then echo "  II empty";return;fi
  echo "$1"
  printf "  $(tput bold)MM SUBMENU: quarantine$(tput sgr0)  [m]-move-into-archives [d]-delete-from-q [q]-abort >" | fold -s -w "$GK_COLS"
  $GK_READ_CMD T_CHAR
  case "$T_CHAR" in
    m) __MOVE_OUT_OF_QUARANTINE "$1";;
    d) __DELETE_FROM_QUARANTINE "$1";;
    q) return ;;
    *) echo "  EE wrong key";return ;;
  esac
}

__SYNC(){
  set -- "$(echo ALL $(ag -o --no-numbers '^[a-z]{3,6}://[A-Za-z0-9.]*[.:][A-Za-z0-9]{1,5}|^#_.*_#$' nodes.dat) | sed -e 's/$/ /' -e 's/_# /=/g' -e 's/#_/ /g' | tr ' ' '\n' | grep -E -v '^.*=$|#|^$' | pipe_if_not_empty $GK_FZF_CMD)"
  set -- "${1#*=}"
  if test -z "$1";then echo "  II empty";return;fi
  if test "$1" = "ALL";then set -- ".";fi
  if test -f my-sync-from-nodes.sh;then ./my-sync-from-nodes.sh "--pattern=$1" || exit;else ./sync-from-nodes.sh "--pattern=$1" || exit;fi
}

__EDIT(){
  set -- "$(printf "$OWN_STREAM #BE CAREFUL!\n$(ls launcher.dat nodes.dat blacklist.dat whitelist.dat search.dat 2> /dev/null)" | pipe_if_not_empty $GK_FZF_CMD | __collum 1)"
  if test -z "$1" || ! test -f "$1";then echo "  II empty";return;fi
  if ! test "$1" = "$OWN_STREAM";then $EDITOR "$1";return;fi
  GK_JM=; GK_LN=
  sed 's/\&bsol;/\\/g' "$OWN_STREAM" > "tmp/$OWN_ALIAS-$OWN_ADDR.itp" || return
  $EDITOR tmp/"$OWN_ALIAS"-"$OWN_ADDR"."itp"; echo
  sed -i 's/\\/\&bsol;/g' "tmp/$OWN_ALIAS-$OWN_ADDR.itp" || return
  if cmp "tmp/$OWN_ALIAS-$OWN_ADDR.itp"  "$OWN_STREAM" > /dev/null 2>&1;then
    echo "  II you haven’t changed anything"
  else
    cd tmp && sha512sum "$OWN_ALIAS-$OWN_ADDR.itp" > "$OWN_ALIAS-$OWN_ADDR.itp.sha512sum" && cd .. || exit
    if ./itp-check.sh "tmp/$OWN_ALIAS-$OWN_ADDR.itp" "tmp/$OWN_ALIAS-$OWN_ADDR.itp.sha512sum";then
      mv "tmp/$OWN_ALIAS-$OWN_ADDR.itp" itp-files || exit ; __OWN_SHA_SUM_UPDATE
    else
      echo "  EE file is not itp conform - abort"
    fi
  fi
  rm -f "tmp/$OWN_ALIAS-$OWN_ADDR.itp"*
}

__REPAIRS(){
  printf "  $(tput bold)MM SUBMENU: repairs$(tput sgr0)  [x]-rebuild-all [y]-rebuild-aliases [t]-restart_tor [i]-restart_i2pd [q]-abort >" | fold -s -w "$GK_COLS"
  $GK_READ_CMD T_CHAR
  echo
  case "$T_CHAR" in
    x) rm -f cache/*.sha512sum ; __INIT_FILES ; ITPFILE=$OWN_STREAM ; __INIT_GLOBALS ;;
    y) __REBUILD_ALIASES ;;
    q) return ;;
    t) pidof tor > /dev/null || eval "nohup tor --quiet &" && printf "\n\n  ## tor restart " ;;
    i) pidof i2pd > /dev/null || eval "nohup i2pd --daemon --loglevel=none &" && printf "\n\n  ## i2pd restart ";;
    *) echo "  EE wrong key";return ;;
  esac
}

__INIT_GLOBALS(){
  if ! grep "$OWN_STREAM" < cache/sane_files > /dev/null;then
    echo "  II            WARNING!            "  | ag "."
    printf "  EE you have no stream selected - this could mean your own file is corrupt\n  II unpack the tarball of your own stream and run [x][x] and restart\n" | ag "."
    echo
  fi
  GK_ID=$(echo "$ITPFILE" | __collum 1 "." | __collum 3 "-")
  GK_ALIAS=$(ag --nonumbers --nocolor "$(basename "$ITPFILE")" cache/aliases | __collum 1 )
}

__HOOK_START(){
  eval "$USER_HOOK_START"
}
__HOOK_ARCHIVE_START(){
  eval "$USER_HOOK_ARCHIVE_START"
}
__USER_RETURN(){
  return
}

__PLUGINS(){
  printf "  $(tput bold)MM SUBMENU: plugins\e[0m\n"
  printf "$USER_PLUGINS_MENU >" | sed 's/\b:__[A-Za-z_]*\b//g' | fold -s -w "$GK_COLS"
  $GK_READ_CMD T_CHAR
  echo
  T_BUF1=0
  for T_LINE in $USER_PLUGINS_MENU;do
    T_BUF1=$(( T_BUF1 + 1 ))
    T_BUF2=$(echo "$T_LINE" | __collum 1 "-")
    if test "$T_BUF2" = "["$T_CHAR"]";then
      eval $(echo "$T_LINE" | __collum 2 ":"); T_CHAR='';break
    fi
  done
  if ! test -z "$T_CHAR";then echo "  EE wrong key";fi
}

__REBUILD_ALIASES(){
  if __TEST_ALIAS_FILE cache/aliases > /dev/null;then echo "  II you have no double aliases, you should abort here";fi
  echo -n "  ?? [c]-continue [a]-abort >"
  $GK_READ_CMD T_CONFIRM; if ! test "$T_CONFIRM" = "c";then printf "\n  II aborted\n";return;fi
  cp cache/aliases tmp/aliases || exit
  $EDITOR tmp/aliases
  if ! __TEST_ALIAS_FILE tmp/aliases > /dev/null;then echo "  EE your file still contains doublettes - abort";rm tmp/aliases;return 1;fi
  if __collum 1 < tmp/aliases | grep -v -E '^[0-9A-Za-z_]{1,12}$';then echo "  EE alias contains not allowed characters or is too long (12 max)";rm tmp/aliases;return 1;fi
  mv tmp/aliases cache/ || exit
  printf "\n  II alias file ok\n"
  ITPFILE=$OWN_STREAM;__INIT_GLOBALS
}

__OWN_SHA_SUM_UPDATE(){
  echo "  ## generating new checksum"
  cd itp-files && sha512sum "$OWN_ALIAS-$OWN_ADDR.itp" > "$OWN_ALIAS-$OWN_ADDR.itp.sha512sum" && cd .. || exit
  printf "  ## signing: "
  if ./sign.sh "$OWN_STREAM".sha512sum && ./check-sign.sh "$OWN_STREAM" 2> /dev/null && ./itp-check.sh "$OWN_STREAM" "$OWN_SUM";then
    cp "$OWN_SUM" cache/ && cp "$OWN_STREAM"* bkp || exit
  else
    echo "  EE signing failed and/or itp-check failed - restoring backup (last change - that caused the error - is lost)"
    cp bkp/"$OWN_ALIAS-$OWN_ADDR.itp" itp-files/ && cp bkp/"$OWN_ALIAS-$OWN_ADDR.itp.sha512sum" itp-files/ && cp bkp/"$OWN_ALIAS-$OWN_ADDR.itp.sha512sum.sig" itp-files/ || exit
    __INIT_FILES
    GK_JM=; GK_LN=
    return 1
  fi
}

### MAIN starts here
echo "  ## $(ls VERSION*) $(cat VERSION*) "

#source start script
. ./.Goldkarpfen.start.sh || exit

#set some globals
GK_JM=; GK_LN=
if command -v fzy > /dev/null 2>&1;then GK_FZF_CMD="fzy";else GK_FZF_CMD="fzf";fi

#create dirs
mkdir -p cache/last_prune archives plugins quarantine sync bkp || exit

./update-archive-date.sh || exit

USER_PLUGINS_MENU="[q]-return_to_main:__USER_RETURN"

#source plugins
if find plugins -name '*\.sh' | ag '\.sh$' > /dev/null;then
  echo -n "  ## loading plugins: "
  for T_FILE in $(ag -f -g "\.sh$" plugins/);do
    if . ./"$T_FILE" 2>&1 > /dev/null;then echo -n "$(basename "${T_FILE%.sh}") ";fi
  done
  echo
fi

#prune if month has changed
if ! test -f cache/last_prune/last_prune;then date --utc +"%m" > cache/last_prune/last_prune;fi
if test $(cat cache/last_prune/last_prune) != $(date --utc +"%m");then
  echo "  II pruning $OWN_STREAM"
  if ./prune-month.sh $(cat cache/last_prune/last_prune) "$OWN_STREAM";then
    if __OWN_SHA_SUM_UPDATE;then date --utc +"%m" > cache/last_prune/last_prune || exit;fi
  fi
fi

#create alias cache if needed - first run or cache rebuild
if ! test -f cache/aliases;then
  if test -f cache/sane_files;then rm cache/sane_files;fi
  for T_FILE in itp-files/*.itp;do
    if ./itp-check.sh "$T_FILE" "$T_FILE.sha512sum";then
      echo "$T_FILE" >> cache/sane_files || exit
    fi
  done
  echo "  ## creating alias file"
  while IFS= read -r T_FILE; do
    T_BUF=$(basename "$T_FILE"| __collum 1 "-" )
    echo "$T_BUF "$(basename "$T_FILE") >> cache/aliases || exit
  done < cache/sane_files
  __TEST_ALIAS_FILE cache/aliases
fi

#create sane files if needed
if ! test -f cache/sane_files;then
  for T_FILE in itp-files/*.itp;do
    if ./itp-check.sh "$T_FILE" "$T_FILE.sha512sum";then
      echo "$T_FILE" >> cache/sane_files || exit
    else
      T_BUF=$(basename "$T_FILE")
      sed -i "/$T_BUF/d" cache/aliases || exit
    fi
  done
fi

#more startup functions
__INIT_FILES
__INIT_GLOBALS
__PRUNE_ARCHIVES
__HOOK_START

#main loop
while true;do
  GK_COLS=$(( $(tput cols) - 5))
  if ! pidof tor > /dev/null && command -v tor > /dev/null;then echo "  II tor off -> [x][t] for restart";fi
  if ! pidof i2pd > /dev/null && command -v i2pd > /dev/null;then echo "  II i2pd off -> [x][i] for restart";fi
  printf "[$GK_MODE] UTC:[$(date --utc "+%m.%d")] MY:$(tput rev)[$OWN_ALIAS]$(tput sgr0) SELECT:$(tput rev)[$GK_ALIAS]$(tput sgr0)$GK_JM\n[v]-view [p]-post [s]-select_stream [u]-unpack [m]-quarantine [a]-archive/release [S]-sync [r]-plugins [!]-edit [x/y]-repairs [h]-help [Q]-quit >" | fold -s -w $GK_COLS
  $GK_READ_CMD T_CHAR
  echo
  case "$T_CHAR" in
    v) __VIEW ;;
    s) __SELECT_STREAM ;;
    p) __POST ;;
    S) __SYNC ;;
    a) __ARCHIVE ;;
    u) __UNPACK ;;
    m) __QUARANTINE ;;
    x) __REPAIRS ;;
    y) __REPAIRS ;;
    h)
      echo; fold -w "$GK_COLS" -s < help-en.dat | sed 's/^/   /';echo
      echo -n "   $(cat VERSION*) ";ls VERSION*
    ;;
    !) __EDIT ;;
    r) __PLUGINS ;;
    Q) exit ;;
    *) echo "  EE wrong key" ;;
  esac
done
#WPfzQ!
