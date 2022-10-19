#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
if ! test -f $(basename $0);then echo "  EE run this script in its folder";exit;fi
mkdir -p tmp
if ./keys.sh;then
  PUBKEY=$(grep -v "^-----" < .keys/pub.pem|tr -d "\n")
  ADDRESS=$(cat .keys/pub_hash)
  if echo $ADDRESS | ag "ERROR" || echo $ADDRESS | ag "^000000000";then echo "FATAL ERROR: key generation failed - abort.";rm .keys/*;exit 1;fi
  echo "  II your KEY_ADDR is: $ADDRESS"
  echo -n "  ?? what alias? "
  read BUF
  if ! echo $BUF | grep -E '^[0-9A-Za-z_]{1,12}$' > /dev/null;then
    >&2 echo "  EE alias contains not allowed characters or is too long (12 max)"
    rm .keys/pub_hash .keys/pub.pem .keys/priv.pem
    exit 1
  fi
  FILENAME="itp-files/$BUF""-"$ADDRESS".itp"
  echo "#ITP" > $FILENAME
  echo "#PEM_PUBKEY $PUBKEY" >> $FILENAME
  echo "#POSTS_BEGIN" >> $FILENAME
  echo "#POSTS_END" >> $FILENAME
  echo "#COMMENTS_BEGIN" >> $FILENAME
  echo "#COMMENTS_END" >> $FILENAME
  echo "#LICENSE:CC0" >> $FILENAME
  sha512sum "$FILENAME" > "$FILENAME".sha512sum
  ./sign.sh "$FILENAME".sha512sum
  echo "# itp-file" > Goldkarpfen.config
  echo "$(basename $FILENAME)" >> Goldkarpfen.config
  echo "# server-port" >> Goldkarpfen.config
  echo "8087" >> Goldkarpfen.config
  echo "$BUF""-""$ADDRESS".itp > blacklist.dat
  echo "Ok"
else
  echo "  II use an extra folder for every account"
  exit 1
fi
