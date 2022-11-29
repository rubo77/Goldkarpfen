#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
#SYNOPSIS
#  itp-check.sh [FILE] [SHA512SUM_FILE]

### file tests
if test -z "$1" || test -z "$2";then
  >&2 echo "  EE usage: itp-check.sh [FILE] [SHA512SUM_FILE]"
  exit 1
fi

FILENAME=$(realpath "$1")
SUMNAME=$(realpath "$2")

if file -b --mime-type "$FILENAME" | sed 's|/.*||' | ag -v "text"  || file -b --mime-type "$SUMNAME" | sed 's|/.*||' | ag -v "text"; then
  >&2 echo "  EE $FILENAME and checksum need to be textfiles"
  exit 1
fi

### filename test
if ! basename "$FILENAME" | ag '^[0-9A-Za-z_]{1,12}-[0-9A-Za-z]{34}.itp$' > /dev/null;then
  >&2 echo "  EE $FILENAME contains not allowed characters or alias is too long (12 max) or KEY_ADDR is wrong"
  exit 1
fi

###format tests
RE_PREFIX='^([0][0-9]|[1][0-2])\.([0][1-9]|[1-2][0-9]|[3][0-1]):[1-9]\s.*'

BUF1="$(ag --no-numbers "^#" "$FILENAME" | sed 's/\s.*$//' | tr -d '\n')"
if ! test "$BUF1" = "#ITP#PEM_PUBKEY#POSTS_BEGIN#POSTS_END#COMMENTS_BEGIN#COMMENTS_END#LICENSE:CC0";then
  >&2 echo "  EE $FILENAME contains not the valid lines in order"
  exit 1
fi

for TAG in "#POSTS_BEGIN" "#POSTS_END" "#COMMENTS_BEGIN" "#COMMENTS_END";do
  BUF=$(ag --no-color --no-numbers "^$TAG" "$FILENAME")
  if test "$BUF" != "$TAG";then
    >&2 echo "  EE $TAG line contains extra characters"
    exit 1
  fi
done

if ! tail -n 1 "$FILENAME" | ag "^#LICENSE:CC0$" > /dev/null && ! tail -n 1 "$FILENAME" | ag "^#LICENSE:CC0 \d\d-\d\d-\d\d$" > /dev/null;then
  >&2 echo "  EE the line #LICENSE:CC0 is malformed or there are lines after it"
  exit 1
fi

if ag '^.{1024}.*' "$FILENAME";then
  >&2 echo "  EE $FILENAME contains lines longer than 1024"
  exit 1
fi

BUF1=$(sed -n '3p' "$FILENAME")
if [ "$BUF1" != "#POSTS_BEGIN" ];then
  >&2 printf "  EE $FILENAME line 3 is malformed - it should be:\n#POSTS_BEGIN"
  exit 1
fi

BUF1=$(sed -n -e '/^#POSTS_END/,$p' "$FILENAME" | sed '/^#COMMENTS_BEGIN/q' | wc -l )
if test "$BUF1" -gt 2;then
  >&2 echo "  EE $FILENAME has excess line between #POSTS_END and #COMMENTS_BEGIN"
  exit 1
fi

if ag --no-color --no-numbers -v "^#" "$FILENAME" | ag -v $RE_PREFIX ;then
  >&2 echo "  EE $FILENAME contains unformatted lines"
  exit 1
fi

###sha512sum test
BUF1=$(awk '{print $1}' "$SUMNAME" )
BUF2=$(sha512sum "$FILENAME" | awk '{print $1}')
if [ "$BUF1" != "$BUF2" ];then
  >&2 echo "  EE $FILENAME sha512sum error"
  exit 1
fi

###prune test
BUF1=$(sed '/^#POSTS_END/q' "$FILENAME" | ag $RE_PREFIX | sed 's/\..*$//' | uniq | sort -k1 -n | uniq | wc -l)
BUF2=$(sed '/^#POSTS_END/q' "$FILENAME" | ag $RE_PREFIX | sed 's/\..*$//' | uniq | sort -k1 -n | wc -l)
if [ "$BUF1" != "$BUF2" ];then
  >&2 echo "  EE $FILENAME is not itp-prune conform or is ordered corruptly"
  exit 1
fi

BUF1=$(sed -n -e '/^#COMMENTS_BEGIN/,$p' "$FILENAME" | ag $RE_PREFIX | sed 's/\..*$//' | uniq | sort -k1 -n | uniq | wc -l)
BUF2=$(sed -n -e '/^#COMMENTS_BEGIN/,$p' "$FILENAME" | ag $RE_PREFIX | sed 's/\..*$//' | uniq | sort -k1 -n | wc -l)
if [ "$BUF1" != "$BUF2" ];then
  >&2 echo "  EE $FILENAME is not itp-prune conform or is ordered corruptly"
  exit 1
fi

###double entry test
BUF1=$(sed '/^#POSTS_END/q' "$FILENAME" | ag $RE_PREFIX | sed 's/\s.*$//' | sort -k1 -n | uniq | wc -l)
BUF2=$(sed '/^#POSTS_END/q' "$FILENAME" | ag $RE_PREFIX | sed 's/\s.*$//' | wc -l)
if [ "$BUF1" != "$BUF2" ];then
  >&2 echo "  EE $FILENAME contains double entries"
  exit 1
fi

###double entry test
BUF1=$(sed -n -e '/^#COMMENTS_BEGIN/,$p' "$FILENAME" | ag $RE_PREFIX | sed 's/\s.*$//' | sort -k1 -n | uniq | wc -l)
BUF2=$(sed -n -e '/^#COMMENTS_BEGIN/,$p' "$FILENAME" | ag $RE_PREFIX | sed 's/\s.*$//' | wc -l)
if [ "$BUF1" != "$BUF2" ];then
  >&2 echo "  EE $FILENAME contains double entries"
  exit 1
fi

###entry order test
for MONTH in $(sed '/^#POSTS_END/q' "$FILENAME" | ag -v '^#' | sed 's/\..*//' | uniq); do
  BUF1="$(sed '/^#POSTS_END/q' "$FILENAME" | ag "^$MONTH.\d\d:\d\s.*" | sed 's/\s.*$//'  | sort -k1 -n )"
  BUF2="$(sed '/^#POSTS_END/q' "$FILENAME" | ag "^$MONTH.\d\d:\d\s.*" | sed 's/\s.*$//')"
  if ! test "$BUF1" = "$BUF2" > /dev/null;then
    >&2 echo "  EE $FILENAME posts are not in order"
    exit 1
  fi
done

for MONTH in $(sed -n -e '/^#COMMENTS_BEGIN/,$p' "$FILENAME" | ag -v '^#' | sed 's/\..*//' | uniq); do
  BUF1="$(sed -n -e '/^#COMMENTS_BEGIN/,$p' "$FILENAME" | ag "^$MONTH.\d\d:\d\s.*" | sed 's/\s.*$//' | sort -k1 -n | tr "\n" " ")"
  BUF2="$(sed -n -e '/^#COMMENTS_BEGIN/,$p' "$FILENAME" | ag "^$MONTH.\d\d:\d\s.*" | sed 's/\s.*$//' | tr "\n" " ")"
  if ! test "$BUF1" = "$BUF2" > /dev/null;then
    >&2 echo "  EE $FILENAME comments are not in order"
    exit 1
  fi
done

exit 0
