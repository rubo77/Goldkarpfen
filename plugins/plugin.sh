#GPL-3 - See LICENSE file for copyright and license details.
USER_PLUGINS_MENU="[P]-_:__USER_DEPR_P $USER_PLUGINS_MENU"
__USER_DEPR_P(){
  echo "P is deprecated, use [g]"
}

USER_PLUGINS_MENU="[g]-get_p:__USER_PLUGIN $USER_PLUGINS_MENU"
__USER_PLUGIN(){
  mkdir -p downloads || exit
  # URL FILENAME-LINK
  set -- "$(ag -m 1 -o "^#ITP.*<url1=[a-z]{3,6}://[A-Za-z0-9.]*[.:][A-Za-z0-9]{1,5}>" "$ITPFILE" 2> /dev/null | sed -e "s/^.*<url1=//" -e "s/>.*//")" "$(ag --no-numbers "<plugin=[a-zA-Z0-9._\-/]*>" "$ITPFILE" | sed -e "s/^.*<.*=//" -e "s/>/ /" | pipe_if_not_empty $GK_FZF_CMD)"
  if test -z "$1";then echo "  II the stream has no url1 tag";return;fi
  if test -z "$2";then echo "  II empty";return;fi
  # URL FILENAME VSTREAM
  set -- "$1" "$(echo $2 | __collum 1)" "$(echo $2 | __collum 2)"
  if test -f downloads/"$(basename $2)";then
    echo -n "  ?? file exists - overwrite? Y/[N] >"
    $GK_READ_CMD T_CONFIRM; if test "$T_CONFIRM" != "Y";then printf "\n  II aborted";return;else echo;fi
  fi
  echo "  ## downloading $2"
  T_CMD=$(__DOWNLOAD_COMMAND "$1" "$2" || echo "__error_getting_dl_cmd;")
  $T_CMD -o downloads/"$(basename $2)" || return
    if file -b --mime-type downloads/"$(basename $2)" | sed 's|/.*||' | ag -v "text";then echo "  EE fatal: $(basename $2) is not a textfile";return 1;fi
    if ! test "$3" = "$(sed -n '3p' downloads/$(basename $2))";then echo "  EE verification-stream mismatch: (posted itp-file and plugin itp-file are different) - abort";return 1; fi
    cd downloads || exit
    if ! ag --no-numbers -Q "$(sha512sum $(basename $2))" ../itp-files/"$(sed -n '3p' $(basename $2) | sed 's/^#//' )";then
      echo "  II download could not be verified!" | ag "."
      printf "  II this can happen due the async-nature of the system (don’t be too upset for now):\n    - you have not the latest verfication stream\n    - the plugin is outdated or broken\n"
      echo "  II inspect and/or delete downloads/$(basename $2) -or- try again tommorow"
      cd ..; return
    fi
    cd ..
    echo -n "  II downloaded version: ";sed -n "2p" downloads/"$(basename $2)"
    echo -n "  II local version     : ";sed -n "2p" plugins/"$(basename $2)" 2> /dev/null | grep "^#"
    echo  -n "  ?? install this plugin? y/[n] >"
    $GK_READ_CMD T_BUF;echo
    if test "$T_BUF" != "y";then echo;return;fi
    mv -v downloads/"$(basename $2)" plugins/ || return
    . plugins/"$(basename $2)" || return
    echo -n "  ?? share-host this file? y/[n] >"
    $GK_READ_CMD T_BUF; if test "$T_BUF" != "y";then echo;return;fi
    if test -f archives/"$2";then
      printf "\n  ?? file exists - overwrite? Y/[N] >"
      $GK_READ_CMD T_CONFIRM; if test "$T_CONFIRM" != "Y";then printf "\n  II aborted\n";return;else echo;fi
    fi
    mkdir -p archives/share || exit
    cp -v plugins/"$(basename $2)" archives/share || return
    echo "  II add a post (or edit an existing one) with:"
    echo "  $(tput rev)<plugin=share/$(basename $2)> $(sed -n '3p' archives/share/$(basename $2)) $(sed -n '2p' archives/share/$(basename $2))$(tput sgr0)"
}
