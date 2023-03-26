#GPL-3 - See LICENSE file for copyright and license details.
#V0.6
#GKdev-1FHDi5veznUojyHaZQ9wv5dwj5aqZmXYGg.itp
USER_PLUGINS_MENU="[l]-launch:__USER_LAUNCH $USER_PLUGINS_MENU"
__USER_LAUNCH(){
  if ! test -f launcher.dat; then
    printf 'echo "edit launcher.dat to add more programs"\nbash #subshell (exit with [CTRL-d])\nfff #file manager\nnano #editor\ncurl -f --progress-bar --proxy socks5://127.0.0.1:9050 --socks5-hostname 127.0.0.1:9050 rate.sx/btc | grep -v " *│" #check btc price\n' > launcher.dat
  fi
  set -- "$(
  cat launcher.dat |
  while IFS= read -r T_LINE; do
    if command -v "$(echo $T_LINE | __collum 1)" > /dev/null 2>&1;then
      echo "$T_LINE"
    fi
  done | pipe_if_not_empty $GK_FZF_CMD)"
  if test -z "$1";then echo "  II empty";return;fi
  eval "$1"
}

