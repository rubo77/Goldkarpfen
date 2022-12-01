#GPL-3 - See LICENSE file for copyright and license details.
#V0.11
#Goldkarpfen-1JULSJ5Nnba9So48zi21rpfTuZ3tqNRaFB.itp
USER_PLUGINS_MENU="[N]-add_node:__USER_ADD_NODE $USER_PLUGINS_MENU"
__USER_ADD_NODE(){

  set "$(ag --no-numbers "<node=.*>" $ITPFILE | sed -e "s/^.*<.*=//" -e "s/>/ /" | pipe_if_not_empty $GK_FZF_CMD)"
  if test -z "$1";then echo "  II empty";return;fi

  set "$(echo "$1" | awk '{print $1}')"

  if grep "$1" nodes.dat;then
    echo "  II this url is already in your node list"
  elif head -n 1 "$OWN_STREAM" | ag -Q "$1";then
    echo "  II this is your own url1"
  else
    echo -n "  ?? sure to add $1 to nodes.dat (y/n) >"
    $GK_READ_CMD T_CONFIRM
    if test "$T_CONFIRM" != "y";then return;fi
    echo $1 >> nodes.dat
    echo
  fi
}
