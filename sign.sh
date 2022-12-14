#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
#EXAMPLE ./sign.sh itp-files/xyz.sha512sum
if ! test -f $(basename "$0");then echo "  EE run this script in its folder";exit 1;fi
trap "rm tmp/$(basename "$1").sigbin; trap - EXIT; exit" EXIT
trap "rm tmp/$(basename "$1").sigbin; trap - EXIT; exit 0" INT HUP TERM QUIT
set -e
openssl dgst -sha256 -sign .keys/priv.pem -out tmp/$(basename "$1").sigbin "$1"
openssl enc -base64 -in tmp/$(basename "$1").sigbin -out itp-files/$(basename "$1").sig
