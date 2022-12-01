#GPL-3 - See LICENSE file for copyright and license details.
USER_PLUGINS_MENU="[U]-update_Goldkarpfen:__USER_UPDATE $USER_PLUGINS_MENU"
__USER_UPDATE(){
  cd update || exit
  echo "  ## FIRST RUN"
  if ./sync_runtime_files.sh --first-run;then
    echo "  ## SECOND RUN"
    ./sync_runtime_files.sh
    echo
    echo "  II restart your Goldkarpfen now " | ag "."
  else
    echo "  II you said no, or something went wrong"
  fi
  cd ..
}
