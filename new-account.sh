#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
if ! test -f $(basename "$0");then echo "  EE run this script in its folder";exit 1;fi
mkdir -p tmp bkp || exit 1
if ! test "$(./keys.sh .keys/test.pem 2> /dev/null)" = "134Euv2ifsALzYqfgMrCjstKqAf5pU2nUx";then
  echo "FATAL ERROR: keys.sh test failed.";exit 1
fi
if ./keys.sh;then
  PUBKEY=$(grep -v "^-----" < .keys/pub.pem|tr -d "\n")
  ADDRESS=$(cat .keys/pub_hash)
  echo "  II your KEY_ADDR is: $ADDRESS"
  echo -n "  ?? what alias? "
  read BUF
  if ! echo "$BUF" | grep -E '^[0-9A-Za-z_]{1,12}$' > /dev/null;then
    >&2 echo "  EE alias contains not allowed characters or is too long (12 max)"
    rm .keys/pub_hash .keys/pub.pem .keys/priv.pem
    exit 1
  fi
  set -e
  FILENAME="itp-files/$BUF-$ADDRESS.itp"
  echo "#ITP" > "$FILENAME"
  echo "#PEM_PUBKEY $PUBKEY" >> "$FILENAME"
  echo "#POSTS_BEGIN" >> "$FILENAME"
  echo "#POSTS_END" >> "$FILENAME"
  echo "#COMMENTS_BEGIN" >> "$FILENAME"
  echo "#COMMENTS_END" >> "$FILENAME"
  echo "#LICENSE:CC0" >> "$FILENAME"
  sha512sum "$FILENAME" > "$FILENAME".sha512sum ; ./sign.sh "$FILENAME".sha512sum
  cp "$FILENAME"* bkp/
  echo "# itp-file" > Goldkarpfen.config
  echo "$(basename "$FILENAME")" >> Goldkarpfen.config
  echo "# SERVER_PORT" >> Goldkarpfen.config
  echo "8087" >> Goldkarpfen.config
  echo "$BUF-$ADDRESS.itp" > blacklist.dat
  echo "Ok"
else
  echo "  II use an extra folder for every account"
  exit 1
fi
