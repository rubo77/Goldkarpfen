#GPL-3 - See LICENSE file for copyright and license details.
if ! test -f Goldkarpfen.config; then echo "  EE the config file Goldkarpfen.config is missing!";exit 1;fi
OWN_STREAM="itp-files/$(sed -n '2 p' Goldkarpfen.config)"

OWN_ALIAS=$(basename "$OWN_STREAM" | sed 's/-.*$//')
OWN_ADDR=$(basename "$OWN_STREAM" | sed 's/^.*-//' | sed 's/\.itp$//')
ITPFILE="$OWN_STREAM"
OWN_SUM="$OWN_STREAM"".sha512sum"
#SERVER_PORT
set "$(sed -n '4 p' Goldkarpfen.config)"

if test -f ./my-start-services.sh;then
  ./my-start-services.sh "$OWN_ADDR" "$1"
elif test "$GK_MODE" = "tor";then
  ./start-services.sh "$OWN_ADDR" "$1"
fi

if ! head -n 1 "$OWN_STREAM" | ag -Q '<url1=' > /dev/null;then
  if echo "$GK_MODE" | ag "tor" > /dev/null;then
    echo "  II retrieve your hostname with: sudo cat /var/lib/tor/$OWN_ADDR/hostname"
    echo "  II add an url1-header-tag with [r][h]"
    echo
  elif test "$GK_MODE" = "i2p";then
    echo "  II retrieve your i2p hostname and add an url1-header-tag with [r][h]"
    echo
  fi
fi
