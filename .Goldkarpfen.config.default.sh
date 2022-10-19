#GPL-3 - See LICENSE file for copyright and license details.
OWN_STREAM="itp-files/rubo77-1MWsjwxj18t53qtUqHiMTcZuiVcGDcNFho.itp"

OWN_ALIAS=$(basename "$OWN_STREAM" | sed 's/-.*$//')
OWN_ADDR=$(basename "$OWN_STREAM" | sed 's/^.*-//' | sed 's/\.itp$//')
ITPFILE="$OWN_STREAM"
OWN_SUM="$OWN_STREAM"".sha512sum"

echo "Using ACCOUNT $OWN_ALIAS"

SERVER_PORT="8087" #change this if you are using more than one instance
if test $MODE = "OK";then
  ./start-services.sh "$OWN_ADDR" "$SERVER_PORT"
  if ! head -n 1 "$OWN_STREAM" | ag -Q '<url1=' > /dev/null;then
    echo " HINT: retrieve your hostname with: sudo cat /var/lib/tor/$OWN_ADDR/hostname"
    echo " HINT: add a header tag with [r][h]"
    echo
  fi
fi
