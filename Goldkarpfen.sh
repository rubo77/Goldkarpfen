#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
if ! test -f $(basename $0);then echo "  EE run this script in its folder";exit;fi
GK_PATH=$(pwd)

#help
if test "$1" = "-h" || test "$1" = "--help";then
  echo "  II USAGE: ./Goldkarpfen.sh"
  exit
fi

#test for dependencies
echo "  ## startup ..."
GK_MODE="ERROR"
if test -f my-check-dependencies.sh;then GK_MODE=$(./my-check-dependencies.sh | tail -n 1);else GK_MODE=$(./check-dependencies.sh | tail -n 1);fi
if test "$GK_MODE" = "ERROR";then exit 1;fi
if which bsdiff > /dev/null 2>&1; then GK_DIFF_MODE="yes";fi #DIFF-PATCH-VERSION else echo "  II install bsdiff to enable diff-mode"

#new account?
if ! test -d .keys;then
  printf "  II FIRST START:\n./new-account\n./Goldkarpfen.sh\n"
  exit
fi

#test if shell can read -n 1
printf "  II setting MODE to: $GK_MODE\n  ?? press [Return] to start >"
if read -n 1 T_CHAR > /dev/null 2>&1;then
  GK_READ_CMD="read -n 1"
else
  GK_READ_CMD="read"
  read T_BUF
fi

#run script on exit
trap "cd $GK_PATH;if __CONFIRM_EXIT; then . ./.Goldkarpfen.exit.sh; trap - EXIT; exit;fi" INT
trap "cd $GK_PATH;. ./.Goldkarpfen.exit.sh; trap - EXIT; exit" EXIT HUP TERM QUIT

#source include
. ./include.sh

USER_HOOK_START="return"; USER_HOOK_ARCHIVE_START="return"

#functions
__CONFIRM_EXIT(){
  if test "$T_CHAR" = "Q";then return 0;fi
  printf "\n  II you pressed [CTRL][C] - ?? exit Goldkarpfen? (y/n) >"
  $GK_READ_CMD T_CONFIRM
  if test "$T_CONFIRM" != "y";then
    printf "\n  II exit aborted\n"
    T_CHAR="";T_CONFIRM=""
    return 1
  fi
}

__CHECK_INPUT(){
  ag --no-numbers --no-color -v "^#" $1 | tr '\n' ' ' | sed -e 's/\\/\&bsol;/g' -e 's/ *$//' > "$1-stripped"
  mv "$1-stripped" "$1"
  if test $(wc -c < "$1") = 0;then echo "  EE input has 0 chars";return 1;fi
  if test $(wc -c < "$1") -gt $2;then echo "  EE input has more than $2 chars";return 1;fi
  if test "$3" = "--post";then
    if ag "^\d\d\.\d\d:\d @" "$1" > /dev/null;then echo "  EE input is formated like a comment";return 1;fi
  fi
}

__COMMENT(){
  if test -z $GK_JM;then echo "  EE no post selected";return;fi
  if ! date -d "20-$(echo $GK_JM | sed -e 's/\./-/' -e 's/:.*//')" > /dev/null;then echo "  EE invalid date - this may be just technical data";return 1;fi
  echo
  sed -n -e "$GK_LN p" "$ITPFILE" -e 's/\&bsol;/\\/g'
  printf "\n  ?? comment this post?  [c]-continue [a]-abort >"
  $GK_READ_CMD T_CONFIRM;if test "$T_CONFIRM" != "c";then printf "\n  II aborted\n";return;fi
  echo
  # PASTE_LINE TODAY
  set "$(ag "^#COMMENTS_END" "$OWN_STREAM"| __collum 1 ":")" "$(date --utc "+%m.%d")"
  # PASTE_LINE TODAY POST_NUMBER
  set "$1" "$2" "$(ag --no-numbers --no-color -B 1 "^#COMMENTS_END" "$OWN_STREAM" | ag "^$2" | sed 's/:/ /' | __collum 2)"
  if test -z "$3";then set "$1" "$2" 1; else set "$1" "$2" $(( $3 + 1 ));fi
  if test $3 -gt 9;then echo "  EE you can only post 9 comments a day";return;fi
  echo "" > tmp/text; echo "#maximum: 971 chars ; lines with # in the beginnig get ignored ; newlines will replaced with spaces." >> tmp/text
  $EDITOR tmp/text
  if ! __CHECK_INPUT tmp/text 971;then echo "  EE input error";rm -f tmp/text;return;fi
  sed -i ""$1"i "$2":$3 $GK_JM @$GK_ID $(sed -n '1p' tmp/text)" "$OWN_STREAM"
  __OWN_SHA_SUM_UPDATE
  if ./itp-check.sh "$OWN_STREAM" "$OWN_SUM";then #just to be sure!
    cp $OWN_SUM cache
  fi
  rm -f tmp/text
}

__SEARCH(){
  if test "$1" = "--comments";then
    # FUZZY_RESULT
    set "$( ag --no-numbers --no-filename "^\d\d\.\d\d:\d \d\d\.\d\d:\d @$GK_ID" itp-files/*.itp | sort -k1 -n -t ":" | sed -e 's/ @.................................. / /' -e 's/\&bsol;/\\/g' | pipe_if_not_empty $GK_FZF_CMD | __collum 2)"
  else
    # POST_BEGIN POST_END
    set "$(( $(ag "^#POSTS_BEGIN" "$ITPFILE"| __collum 1 ":") + 1 ))" "$(( $(ag "^#POSTS_END" "$ITPFILE"| __collum 1 ":") - 1 ))"
    # FUZZY_RESULT POST_BEGIN POST_END
    set "$(sed -n -e "$1 , $2 p" "$ITPFILE" -e 's/\&bsol;/\\/g' | ag "^\d\d.\d\d:\d " | pipe_if_not_empty $GK_FZF_CMD | __collum 1)" "$1" "$2"
  fi
  if test -z "$1";then return;fi
  # FUZZY_RESULT LINE
  set "$1" "$(grep -n "^$1 " "$ITPFILE" | head -n 1 | __collum 1 ":")"
  if test -z "$2";then return;fi
  GK_JM="$1"
  GK_LN="$2"
}

__VIEW(){
  # BEGIN_LINE END_LINE TERM_COLLUMS
  set "$(( $(ag "^#POSTS_BEGIN" "$ITPFILE"| __collum 1 ":") + 1 ))" "$(( $(ag "^#POSTS_END" "$ITPFILE"| __collum 1 ":") - 1 ))"
  if test $2 = 3;then echo "  II empty";return;fi
  if test -z $GK_LN;then
    T_COUNTER=$2
  else
    T_COUNTER=$GK_LN
  fi
  printf "\n  \e[4mMM SUBMENU: viewer\e[0m  [t]-topic [/]-search_comments [n]-next [p]-previous [c]-comment [q]-exit_viewer\n"
  T_BUF=1
  while true;do
    if ! test $T_BUF = 0;then
      T_BUF1=$(sed -n "$T_COUNTER p" $ITPFILE)
      T_BUF2=$(echo $T_BUF1 | __collum 1)
      echo "* $T_BUF1" | sed 's/\&bsol;/\\/g' | fold -w $GK_COLS -s
      ag --no-numbers --no-heading "^\d\d\.\d\d:\d $T_BUF2 @$GK_ID" itp-files/*.itp | sort -k2 -n -t ":" |
      while IFS= read -r LLL;do
        T_BUF1=$(echo $LLL | __collum 2 "/" | __collum 1 ":" | __collum 1 "." | __collum 2 "-")
        T_BUF2=$(echo $LLL | __collum 2 ":" )
        echo $LLL | sed -e "s/^.*@.................................../$T_BUF2 \[$(ag --no-color --no-numbers $T_BUF1 cache/aliases | __collum 1)\] /" -e 's/\&bsol;/\\/g' | fold -w $GK_COLS -s | sed 's/^/    /'
      done
      if test $T_COUNTER = $1;then printf "^^^^^";fi
      if test $T_COUNTER = $2;then printf "_____";fi
      T_BUF=0
    fi
    GK_JM="$T_BUF2"
    GK_LN="$T_COUNTER"
    $GK_READ_CMD T_CHAR ;printf "\r"
    case "$T_CHAR" in
      "") echo ;;
      n)
        if test $T_COUNTER -lt $2;then
          T_COUNTER=$(( T_COUNTER + 1 ));T_BUF=1
        fi
      ;;
      p)
        if test $T_COUNTER -gt $1;then
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
        printf "\n  \e[4mMM SUBMENU: viewer\e[0m  [t]-topic [/]-search_comments [n]-next [p]-previous [c]-comment [q]-exit_viewer\n"
        ;;
      q) GK_LN=$T_COUNTER;break ;;
    esac
  done
}

__SELECT_STREAM(){
  if ! test -s ./cache/aliases;then printf "  EE you have no files to choose from - this can happen if you have non-conform itp files\n  II try rebuilding your aliases and rebuild all [y][y] [x][x]\n";return;fi
  set "$(__collum 1 < ./cache/aliases | pipe_if_not_empty $GK_FZF_CMD)"
  if test -z "$1" || ! ag "^$1" ./cache/aliases > /dev/null;then echo "  II empty";return;fi
  ITPFILE="itp-files/"$(ag --nonumbers --nocolor "^$1 " cache/aliases | head -n 1 | __collum 2)
  GK_JM=""; GK_LN=""
  __INIT_GLOBALS
}

__POST(){
  # PASTE_LINE TODAY
  set "$(ag "^#POSTS_END" "$OWN_STREAM" | __collum 1 ":")" "$(date --utc "+%m.%d")"
  # PASTE_LINE TODAY POST_NUMBER
  set "$1" "$2" "$(ag --no-numbers --no-color -B 1 "^#POSTS_END" "$OWN_STREAM" | ag "^$2" | sed 's/:/ /' | __collum 2)"
  if test -z "$3";then set "$1" "$2" 1; else set "$1" "$2" $(( $3 + 1 ));fi
  if test $3 -gt 9;then echo "  EE you can only post 9 posts a day";return;fi
  echo "" > tmp/text; echo "#maximum: 1007 chars ; lines with # in the beginnig get ignored ; newlines will replaced with spaces." >> tmp/text
  $EDITOR tmp/text
  if ! __CHECK_INPUT tmp/text 1007 --post;then echo "  EE input error";rm -f tmp/text;return;fi
  echo "$2:""$3 $(sed -n '1p' tmp/text)" | sed 's/\&bsol;/\\/g'
  echo -n "  ?? add this post? [c]-continue [a]-abort >"
  $GK_READ_CMD T_CONFIRM;if test "$T_CONFIRM" != "c";then printf "\n  II aborted\n";rm -f tmp/text;return;fi
  echo
  sed -i ""$1"i "$2":$3 $(sed -n '1p' tmp/text)" $OWN_STREAM
  rm -f tmp/text
  __OWN_SHA_SUM_UPDATE
  if ./itp-check.sh "$OWN_STREAM" "$OWN_SUM";then #just to be sure!
    cp "$OWN_SUM" cache
  fi
  GK_JM="$2"":"$3 ;GK_LN=$1
}

__ARCHIVE(){
  __HOOK_ARCHIVE_START
  echo "  ## sanity check"
  if ./itp-check.sh $OWN_STREAM $OWN_SUM;then echo "  II your file is itp conform";else echo "  EE your itp file is not conform!";return;fi
  if test -f "archives/$OWN_ALIAS-$OWN_ADDR.itp.tar.gz" && test "$(tar xOf "archives/$OWN_ALIAS-$OWN_ADDR.itp.tar.gz" "$OWN_ALIAS-$OWN_ADDR.itp.sha512sum")" = "$(cat "itp-files/$OWN_ALIAS-$OWN_ADDR.itp.sha512sum")";then
    echo "  II you haven’t changed anything - abort"; return
  fi
  sed -i "s/^#LICENSE:CC0.*$/#LICENSE:CC0 $(date --utc '+%y-%m-%d')/" "$OWN_STREAM"
  __OWN_SHA_SUM_UPDATE; cp "$OWN_SUM" cache
  echo "  ## archiving"
  if tar cfv "tmp/$OWN_ALIAS-$OWN_ADDR.itp.tar" --mtime="$(date +'%Y-%m-%d %H:00')" -C itp-files "$OWN_ALIAS-$OWN_ADDR.itp.sha512sum" "$OWN_ALIAS-$OWN_ADDR.itp" "$OWN_ALIAS-$OWN_ADDR.itp.sha512sum.sig" --utc --numeric-owner;then
    if test -f "archives/$OWN_ALIAS-$OWN_ADDR.itp.tar.gz";then
      if test -f "bkp/$OWN_ALIAS-$OWN_ADDR.itp.tar" && test "$GK_DIFF_MODE" = "yes" > /dev/null 2>&1;then
        set  "$(date --utc -d "$(tar -tvf "tmp/$OWN_ALIAS-$OWN_ADDR.itp.tar" --utc "$OWN_ALIAS-$OWN_ADDR.itp.sha512sum" | __collum 4)" +"%y-%m-%d")" "$(date --utc -d "$(tar -tvf "bkp/$OWN_ALIAS-$OWN_ADDR.itp.tar" --utc "$OWN_ALIAS-$OWN_ADDR.itp.sha512sum" | __collum 4)" +"%y-%m-%d")"
        if ! test "$1" = "$2";then
          echo "  II generating diff from $2"
          bsdiff "bkp/$OWN_ALIAS-$OWN_ADDR.itp.tar" "tmp/$OWN_ALIAS-$OWN_ADDR.itp.tar" "tmp/$OWN_ALIAS-$OWN_ADDR.itp.tar.gz_D$2"
        fi
      fi
      rm -f "bkp/__$OWN_ALIAS-$OWN_ADDR.itp.tar"; cp "tmp/$OWN_ALIAS-$OWN_ADDR.itp.tar" bkp/
      set  "$(date --utc -d "$(tar -tvf "archives/$OWN_ALIAS-$OWN_ADDR.itp.tar.gz" --utc "$OWN_ALIAS-$OWN_ADDR.itp.sha512sum" | __collum 4)" +"%y-%m-%d")" "$(date --utc -d "$(tar -tvf "tmp/$OWN_ALIAS-$OWN_ADDR.itp.tar" --utc "$OWN_ALIAS-$OWN_ADDR.itp.sha512sum" | __collum 4)" +"%y-%m-%d")" "$2"
      if test "$1" = "$2";then
        mv "bkp/$OWN_ALIAS-$OWN_ADDR.itp.tar" "bkp/__$OWN_ALIAS-$OWN_ADDR.itp.tar"; echo "  II rearchived - diff for $1 blocked"
      fi
    fi
    gzip "tmp/$OWN_ALIAS-$OWN_ADDR.itp.tar"
    rm -f "archives/$OWN_ALIAS-$OWN_ADDR.itp.tar.gz_D"*
    if test -f "tmp/$OWN_ALIAS-$OWN_ADDR.itp.tar.gz_D$3";then mv "tmp/$OWN_ALIAS-$OWN_ADDR.itp.tar.gz_D$3" archives;fi
    mv "tmp/$OWN_ALIAS-$OWN_ADDR.itp.tar.gz" archives
  fi
  ./update-archive-date.sh "$OWN_ALIAS-$OWN_ADDR.itp.tar.gz"
  if test "$(du "archives/$OWN_ALIAS-$OWN_ADDR.itp.tar.gz" | __collum 1)" -gt "318";then echo "  II WARNING: your archive exeeds the size limit of 318kB " | ag ".";fi
}

__UNPACK(){
  set "$(ag -f -g "\.itp\.tar\.gz$" quarantine/ archives/ | pipe_if_not_empty $GK_FZF_CMD )"
  if test -z "$1" || ! test -f "$1";then echo "  II empty";return;fi
  if ! __TEST_ARCHIVE_DATE "$1";then
    echo -n "  ?? force unpack? (Y/n) >"
    $GK_READ_CMD T_CONFIRM;if test "$T_CONFIRM" != "Y";then printf "\n  II aborted\n";return;else echo;fi
  fi
  printf "  ## unpacking...\n"
  if ! __TEST_AND_UNPACK_ARCHIVE "$1";then ./update-archive-date.sh $(basename "$1");return;fi
  if echo $1 | ag '^quarantine/' > /dev/null;then
    echo "  II first unpack of this itp-stream - review it first and then move it out of quarantine with [m]"
  fi
  __INIT_FILES
}

__MOVE_OUT_OF_QUARANTINE (){
  printf "\n  ## moving $1\n"
  mv "$1" archives
  ./update-archive-date.sh $(basename "$1" )
  __INIT_FILES
}

__DELETE_FROM_QUARANTINE (){
  printf "\n  ## removing $1\n"
  if test "$(basename $ITPFILE)" = "$(basename ${1%.tar.gz})";then ITPFILE=$OWN_STREAM; __INIT_GLOBALS;fi
  rm "$1"
  rm -f "itp-files/"$(basename "$1" | __collum 1 "." ).itp
  __INIT_FILES
  echo -n "  ?? add this stream to your blacklist? (y/n) >"
  $GK_READ_CMD T_CONFIRM;if test "$T_CONFIRM" != "y";then printf "\n  II blacklisting skipped\n";return;fi
  echo $(basename "$1") >> blacklist.dat
  sort <  blacklist.dat | uniq > tmp/blacklist.dat ; mv tmp/blacklist.dat ./blacklist.dat
}

__QUARANTINE(){
  set "$(ag -f -g "\.itp\.tar\.gz$" quarantine/ | pipe_if_not_empty $GK_FZF_CMD)"
  if test -z "$1" || ! test -f "$1";then echo "  II empty";return;fi
  echo "$1"
  printf "  \e[4mMM SUBMENU: quarantine\e[0m  [m]-move-into-archives [d]-delete-from-q [q]-abort >"
  $GK_READ_CMD T_CHAR
  case "$T_CHAR" in
    m) __MOVE_OUT_OF_QUARANTINE "$1";;
    d) __DELETE_FROM_QUARANTINE "$1";;
    q) return ;;
    *) echo "  EE wrong key";return ;;
  esac
}

__EDIT(){
  if ! ag "$OWN_STREAM" cache/sane_files > /dev/null;then echo "  EE your own stream is not in the sane list";return;fi
  echo "  II editing your own stream be careful - be CAREFUL!"
  echo -n "  ?? [c]-continue [a]-abort >"
  $GK_READ_CMD T_CONFIRM; if test "$T_CONFIRM" != "c";then printf "\n  II aborted\n";return;fi
  GK_JM=""; GK_LN=""
  cat $OWN_STREAM | sed 's/\&bsol;/\\/g' "$OWN_STREAM" > tmp/"$OWN_ALIAS"-"$OWN_ADDR"."itp"
  $EDITOR tmp/"$OWN_ALIAS"-"$OWN_ADDR"."itp"; echo
  cat tmp/"$OWN_ALIAS"-"$OWN_ADDR"."itp" | sed 's/\\/\&bsol;/g' > tmp/"$OWN_ALIAS"-"$OWN_ADDR"."itp"."clean"
  if cmp "tmp/$OWN_ALIAS-$OWN_ADDR.itp.clean"  "$OWN_STREAM" > /dev/null 2>&1;then
    echo "  II you haven’t changed anything"
  else
    mv "tmp/$OWN_ALIAS-$OWN_ADDR.itp.clean" "tmp/$OWN_ALIAS-$OWN_ADDR.itp"
    cd tmp; sha512sum "$OWN_ALIAS-$OWN_ADDR.itp" > "$OWN_ALIAS-$OWN_ADDR.itp.sha512sum";cd ..
    if ./itp-check.sh "tmp/$OWN_ALIAS-$OWN_ADDR.itp" "tmp/$OWN_ALIAS-$OWN_ADDR.itp.sha512sum";then
      cp "tmp/$OWN_ALIAS-$OWN_ADDR.itp" itp-files
      __OWN_SHA_SUM_UPDATE
      __INIT_FILES
    else
      echo "  EE file is not itp conform - abort"
    fi
  fi
  rm -f "tmp/$OWN_ALIAS-$OWN_ADDR.itp"*
}

__REPAIRS(){
  printf "  \e[4mMM SUBMENU: repairs\e[0m  [x]-rebuild-all [y]-rebuild-aliases [q]-abort >"
  $GK_READ_CMD T_CHAR
  echo
  case "$T_CHAR" in
    x) __REBUILD_ALL ;;
    y) __REBUILD_ALIASES ;;
    q) return ;;
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

__REBUILD_ALL(){
  rm -f cache/*.sha512sum
  __INIT_FILES
  ITPFILE=$OWN_STREAM;__INIT_GLOBALS
}

__HOOK_START(){
  $USER_HOOK_START
}
__HOOK_ARCHIVE_START(){
  $USER_HOOK_ARCHIVE_START
}
__USER_RETURN(){
  return
}

__PLUGINS(){
  printf "  \e[4mMM SUBMENU: plugins\e[0m\n"
  printf "$USER_PLUGINS_MENU >" | sed 's/\b:__[A-Za-z_]*\b//g' | fold -s -w $GK_COLS
  $GK_READ_CMD T_CHAR
  echo
  T_BUF1=0
  for T_LINE in $USER_PLUGINS_MENU;do
    T_BUF1=$(( T_BUF1 + 1 ))
    T_BUF2=$(echo $T_LINE | __collum 1 "-")
    if test "$T_BUF2" = "["$T_CHAR"]";then
      eval $(echo $T_LINE | __collum 2 ":"); T_CHAR='';break
    fi
  done
  if ! test -z $T_CHAR;then echo "  EE wrong key";fi
}

__REBUILD_ALIASES(){
  if ! __TEST_DOUBLE_ALIASES cache/aliases;then echo "  II you have no double aliases, you should abort here";fi
  echo -n "  ?? [c]-continue [a]-abort >"
  $GK_READ_CMD T_CONFIRM; if ! test "$T_CONFIRM" = "c";then printf "\n  II aborted\n";return;fi
  cp cache/aliases tmp/aliases
  $EDITOR tmp/aliases
  if __TEST_DOUBLE_ALIASES tmp/aliases;then echo "  EE your file still contains doublettes - abort";rm tmp/aliases;return 1;fi
  if __collum 1 < tmp/aliases | grep -v -E '^[0-9A-Za-z_]{1,12}$';then echo "  EE alias contains not allowed characters or is too long (12 max)";rm tmp/aliases;return 1;fi
  mv tmp/aliases cache/
  printf "\n  II alias file ok\n"
  ITPFILE=$OWN_STREAM;__INIT_GLOBALS
}

__OWN_SHA_SUM_UPDATE(){
  echo "  ## generating new checksum"
  cd itp-files
  sha512sum "$OWN_ALIAS-$OWN_ADDR.itp" > "$OWN_ALIAS-$OWN_ADDR.itp.sha512sum"
  cd ..
  printf "  ## signing: "
  if ./sign.sh "$OWN_STREAM".sha512sum && ./check-sign.sh "$OWN_STREAM" 2> /dev/null;then cp $OWN_STREAM* bkp; else echo "  EE signing failed";fi
}

### MAIN starts here
if ! ag -f -g "\.itp$" itp-files/ > /dev/null;then echo "  EE no itp file in itp-files"; exit 1;fi
echo "  ## Goldkarfpen $(cat VERSION*) "$(ls VERSION*)

#source start script
. ./.Goldkarpfen.start.sh

#set some globals
GK_JM=""; GK_LN=""
if which fzy > /dev/null 2>&1;then GK_FZF_CMD="fzy";else GK_FZF_CMD="fzf";fi

#create dirs
mkdir -p cache/last_prune archives plugins quarantine sync bkp

./update-archive-date.sh

USER_PLUGINS_MENU="[q]-return_to_main:__USER_RETURN"

#source plugins
if find plugins -name '*\.sh' | ag '\.sh$' > /dev/null;then
  echo -n "  ## loading plugins: "
  for T_FILE in $(ag -f -g "\.sh$" plugins/);do
    if . ./"$T_FILE" 2>&1 > /dev/null;then echo -n "$(basename ${T_FILE%.sh}) ";fi
  done
  echo
fi

#prune if month has changed
if ! test -f cache/last_prune/last_prune;then date --utc +"%m" > cache/last_prune/last_prune;fi
if test $(cat cache/last_prune/last_prune) != $(date --utc +"%m");then
  echo "  II pruning $OWN_STREAM"
  if ./prune-month.sh $(cat cache/last_prune/last_prune) "$OWN_STREAM";then
    date --utc +"%m" > cache/last_prune/last_prune
    __OWN_SHA_SUM_UPDATE
    __INIT_FILES
  fi
fi

#create alias cache if needed - first run or cache rebuild
if ! test -f cache/aliases;then
  if test -f cache/sane_files;then rm cache/sane_files;fi
  for T_FILE in itp-files/*.itp;do
    if ./itp-check.sh "$T_FILE" "$T_FILE"".sha512sum";then
      echo "$T_FILE" >> cache/sane_files
    fi
  done
  echo "  ## creating alias file"
  while IFS= read -r T_FILE; do
    T_BUF=$(basename "$T_FILE"| __collum 1 "-" )
    echo "$T_BUF "$(basename $T_FILE) >> cache/aliases
  done < cache/sane_files
  if __TEST_DOUBLE_ALIASES cache/aliases;then
    printf "\n  II WARNING: you have double aliases - pls run [y][y] after initialization\n"
  fi
fi

#create sane files if needed
if ! test -f cache/sane_files;then
  for T_FILE in itp-files/*.itp;do
    if ./itp-check.sh "$T_FILE" "$T_FILE.sha512sum";then
      echo "$T_FILE" >> cache/sane_files
    else
      T_BUF=$(basename "$T_FILE")
      sed -i "/$T_BUF/d" cache/aliases
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
  printf "\n[$GK_MODE] UTC:[$(date --utc "+%m.%d")] ACCOUNT:\e[7m[$OWN_ALIAS]\e[0m STREAM:\e[7m[$GK_ALIAS]\e[0m TOPIC_ID: [$GK_JM] [$GK_LN]\n[v]-view [p]-post [s]-select_stream [u]-unpack [m]-quarantine [a]-archive [r]-plugins [!]-edit [x/y]-repairs [h]-help [Q]-quit >" | fold -s -w $GK_COLS
  $GK_READ_CMD T_CHAR
  echo
  case "$T_CHAR" in
    v) __VIEW ;;
    s) __SELECT_STREAM ;;
    p) __POST ;;
    a) __ARCHIVE ;;
    u) __UNPACK ;;
    m) __QUARANTINE ;;
    x) __REPAIRS ;;
    y) __REPAIRS ;;
    h)
      echo; fold -w $GK_COLS -s < help-en.dat | sed 's/^/   /' | more;echo
      echo -n "   $(cat VERSION*) ";ls VERSION*
    ;;
    !) __EDIT ;;
    r) __PLUGINS ;;
    Q) exit ;;
    *) echo "  EE wrong key" ;;
  esac
done
#WPfzQ!
