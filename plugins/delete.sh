#GPL-3 - See LICENSE file for copyright and license details.
#V0.15
#Goldkarpfen-1JULSJ5Nnba9So48zi21rpfTuZ3tqNRaFB.itp
USER_PLUGINS_MENU="[D]-delete:__USER_DELETE $USER_PLUGINS_MENU"
__USER_DELETE(){
  . ./update-provider.inc.sh || exit
  if test -z "$UPD_NAME";then UPD_NAME="$GK_UPD_NAME";fi
  if test -z "$VERIFICATION_STREAM";then UPD_NAME="$GK_VERIFICATION_STREAM";fi
  T_BUF=$(printf "$(cat cache/sane_files)\n$(ls archives/*.itp.tar.gz 2> /dev/null)\n" | grep -v "$OWN_STREAM" | grep -v "$UPD_NAME" | grep -v "$VERIFICATION_STREAM" | pipe_if_not_empty $GK_FZF_CMD)
  if test -z "$T_BUF";then echo "  II empty";return;fi
  echo -n "  ?? really delete $T_BUF? Y/[N] >"
  $GK_READ_CMD T_CONFIRM;if test "$T_CONFIRM" != "Y";then printf "\n  II aborted\n";return;fi
  ITPFILE=$OWN_STREAM; __INIT_GLOBALS
  if test "$(echo $T_BUF | __collum 1 "/")" = "archives";then
    rm "$T_BUF"*
    ./update-archive-date.sh $(basename "$T_BUF") || exit
    printf "\n  II archive file $T_BUF deleted"
  elif test "$(echo $T_BUF | __collum 1 "/")" = "itp-files";then
    T_BUF1=$(head -n 1 "$T_BUF" | ag -o '<url1=(\bhttp\b|\bgopher\b)://[0-9A-Za-z]{1,80}\..*>' | sed -e "s/^.*<.*=.*\/\///" -e "s/>//")
    rm "$T_BUF";echo
    __INIT_FILES
    echo "  II itp-file $T_BUF deleted"
    if ! test -z "$T_BUF1";then
      printf "\n  ?? remove url1 ($T_BUF1) from nodes.dat? y/[n] >"
      $GK_READ_CMD T_CONFIRM;
      if test "$T_CONFIRM" != "y";then
        printf "\n  II nodes-delete skipped\n"
      else
        echo
        sed -i "/$T_BUF1/d" nodes.dat
      fi
    fi
  fi
  printf "\n  ?? add this stream to your blacklist? y/[n] >"
  $GK_READ_CMD T_CONFIRM;
  if test "$T_CONFIRM" != "y";then
    printf "\n  II blacklisting skipped\n"
  else
    echo
    echo $(basename "$T_BUF") >> blacklist.dat && sort <  blacklist.dat | uniq > tmp/blacklist.dat && mv tmp/blacklist.dat ./blacklist.dat || exit
  fi
  T_BUF=$(basename $T_BUF)
  if ag -g "${T_BUF%.tar.gz}$|$T_BUF$|$T_BUF.tar.gz$" itp-files archives;then echo "  II also exists";fi
}
