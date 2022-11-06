#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
if ! test -f $(basename $0);then echo "  EE run this script in its folder";exit;fi
trap "rm -f tmp/*.sigbin tmp/pub.pem; trap - EXIT; exit" EXIT INT HUP TERM QUIT

FILE="$1"; SUM="$1"".sha512sum"; SIG="$1"".sha512sum.sig"

if file -b --mime-type $SIG | sed 's|/.*||' | ag -v "text"; then
  >&2 echo "  EE $SIG needs to be a textfile"
  exit 1
fi

echo "-----BEGIN PUBLIC KEY-----" > tmp/pub.pem
sed -n "2p" "$FILE" | awk '{print $2}' | fold -w 65 >> tmp/pub.pem
echo "-----END PUBLIC KEY-----" >> tmp/pub.pem

#if ! test "$(basename ${FILE%.itp} | sed "s/^.*-//")" = "$(./keys.sh tmp/pub.pem | sed 's/^0*//')";then ### after migration timeout
if ! test "$(printf "%34s\n" "$(basename ${FILE%.itp} | sed "s/^.*-//" | sed 's/^0*//')" | sed 'y/ /1/')" = "$( printf "%34s\n" "$(./keys.sh tmp/pub.pem | sed 's/^0*//')" | sed 'y/ /1/' )";then
  printf "%34s\n" "$(./keys.sh .keys/pub.pem | sed 's/^0*//')" | sed 'y/ /1/'
  >&2 echo "  EE pubkey / address mismatch error"
  exit 1
fi

openssl enc -base64 -d -in "$SIG" -out tmp/$(basename "$SIG").sigbin
if ! openssl dgst -sha256 -verify tmp/pub.pem -signature tmp/$(basename "$SIG").sigbin "$SUM";then
  exit 1;
fi
