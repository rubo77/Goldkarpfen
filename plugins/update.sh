#GPL-3 - See LICENSE file for copyright and license details.
USER_PLUGINS_MENU="[U]-updateGK:__USER_UPDATE $USER_PLUGINS_MENU"
__USER_UPDATE(){
  cd update || exit
  echo "  ## FIRST RUN"
  if ./sync_runtime_files.sh --first-run;then
    sync
    echo "  ## SECOND RUN"
    if ./sync_runtime_files.sh;then echo "  II restart your Goldkarpfen now " | ag "."
    else echo "  EE fatal error : it is recommended to exit Goldkarpfen now!";fi
  else
    echo "  II you said no, or something went wrong"
  fi
  cd ..
}
