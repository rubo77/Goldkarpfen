#!/bin/sh
# This is free and unencumbered software released into the public domain.
# parts from grondilu https://bitcointalk.org/index.php?topic=10970.msg156708#msg156708, adapted to work with posix shell
if ! test -f $(basename "$0");then echo "  EE run this script in its folder";exit 1;fi
mkdir -p -m 700 .keys || exit 1
if test -z "$1" && test -f .keys/pub.pem;then >&2 echo "  EE there are already keys, which implies that you have an active account already";exit 1;fi

encode_58() {
    T_BUF=$1
    set 1 2 3 4 5 6 7 8 9 A B C D E F G H J K L M N P Q R S T U V W X Y Z a b c d e f g h i j k m n o p q r s t u v w x y z
    echo -n "$T_BUF" | sed -e 's/^\(\(00\)*\).*/\1/' -e 's/00/1/g' | tr -d '\n'
    dc -e "16i $(echo $T_BUF | tr '[:lower:]' '[:upper:]') [3A ~r d0<x]dsxx +f" |
    while read -r n; do T_BUF1="echo -n \${"$(($n + 1))"}"; eval $T_BUF1; done
}

checksum() {
    echo $1 | xxd -p -r | openssl dgst -sha256 -binary | openssl dgst -sha256 -binary | xxd -p -c 80 | cut -c 1-8
}

hash160() {
    openssl dgst -sha256 -binary | openssl dgst $RMD_OPTION -binary | xxd -p -c 80
}

hash160ToAddress() {
    printf "%34s\n" "$(encode_58 "00$1$(checksum "00$1")")" | sed "y/ /0/"
}

publicKeyToITP59Address() {
    hash160ToAddress $(openssl ec -pubin -pubout -outform DER | tail -c 65 | hash160)
}

if ! echo "JCsmD" | openssl dgst -rmd160 > /dev/null 2>&1; then RMD_OPTION="-rmd160 -provider legacy";else RMD_OPTION='-rmd160';fi

if test -z "$1";then
  #generating keypair pem
  touch .keys/priv.pem && chmod 600 .keys/priv.pem || exit 1
  openssl ecparam -name secp256k1 -genkey -out .keys/priv.pem
  openssl ec -in .keys/priv.pem -pubout -out .keys/pub.pem
  #generating keys
  touch .keys/private-key && chmod 600 .keys/private-key || exit 1
  openssl ec -in .keys/priv.pem -outform DER|tail -c +8|cut -c 1-32|xxd -p -c 32 > .keys/private-key
  openssl ec -in .keys/priv.pem -pubout -outform DER|tail -c 65|xxd -p -c 65 > .keys/public-key
  #ITP59Address encoding
  if openssl ec -pubin -pubout -outform DER < .keys/pub.pem > /dev/null;then
    publicKeyToITP59Address < .keys/pub.pem > .keys/pub_hash
  else
    echo "ERROR" > .keys/pub_hash
  fi
else
  if openssl ec -pubin -pubout -outform DER < "$1" > /dev/null;then
    publicKeyToITP59Address < "$1"
  else
    echo "ERROR"
  fi
fi
