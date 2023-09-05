#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
if ! test -f $(basename "$0");then echo "  EE run this script in its folder";exit 1;fi
if ! test -d itp-files/ || ! test -d cache || ! test -f Goldkarpfen.config;then echo "  EE run this script in a Goldkarpfen-folder";exit;fi
_URL="$(head -n 1 itp-files/$(sed -n '2p' Goldkarpfen.config) | ag -o 'url1=.*\.[A-za-z]*')";_URL="${_URL##*=}"
_DAYS=10;_BLACKLIST=;_WHITELIST=;_TITLE="Goldkarpfen stream selection by: $(sed -n '2p' Goldkarpfen.config | sed 's/-.*//')"
for _ARG in $@;do
  if test "$_ARG" = "--help";then echo "  II usage: ./generate-html.sh [--days=25] [--extra="00.01:3_00.02:1"] [--title=test_aaa] [--show-node-id] [--blacklist=\"elo-|PosRotTurm-\"] [--whitelist=\"elo-|prt-\"] --include=foot.inc --out=/tmp/index.html";echo "  II blacklist and whitelist are EXCLUSIVE";exit;fi
  if test "${_ARG%%=*}" = "--days"; then
    _DAYS="${_ARG##*=}";shift
    if ! test "$_DAYS" = "$(printf "%i" "$_DAYS" 2> /dev/null)";then echo "  EE days is not a number";exit;fi
  fi
  if test "${_ARG%%=*}" = "--blacklist";then _BLACKLIST="${_ARG##*=}";shift;fi
  if test "${_ARG%%=*}" = "--whitelist";then _WHITELIST="${_ARG##*=}";shift;fi
  if test "${_ARG%%=*}" = "--include";then _INC="${_ARG##*=}";shift;fi
  if test "${_ARG%%=*}" = "--title";then _TITLE="$(echo ${_ARG##*=}| sed 's/_/ /g')";shift;fi
  if test "${_ARG%%=*}" = "--extra";then _EXTRA="$(echo ${_ARG##*=}| sed 's/_/ /g')";shift;fi
  if test "${_ARG%%=*}" = "--out"; then _OUT="${_ARG##*=}";shift;fi
  if test "${_ARG%%=*}" = "--show-node-id"; then _SHOW=1;shift;fi
done
set -e
if ! test -z "$_IGNORE";then if ! echo "$_IGNORE" | ag "$_IGNORE" > /dev/null;then echo "  EE bad value for --ignore";exit;fi;fi
if test -z "$_OUT";then echo "  EE no outfile: e.g. use --out=/tmp/index.html"; echo "  WW do NOT use output redirection ( ... > file )";exit;fi

if ! test -z "$_BLACKLIST";then _FIND_CMD="find itp-files/ -name '*.itp' | ag -v \"$_BLACKLIST\""
elif ! test -z "$_WHITELIST";then _FIND_CMD="find itp-files/ -name '*.itp' | ag \"$_WHITELIST\""
else _FIND_CMD="find itp-files/ -name '*.itp'";fi
_FILELIST=$(eval "$_FIND_CMD" | tr '\n' ' ');if test -z "$_FILELIST";then echo "  EE no itp-files found";exit;fi
echo "  II generating posts and comments"
echo "<html>" > "$_OUT"
echo "<head>" >> "$_OUT"
echo "<meta charset="UTF-8">" >> "$_OUT"
echo "<style>div {word-break: break-all;word-break: break-word;-webkit-hyphens: auto;-moz-hyphens: auto;hyphens: auto;}</style>" >> "$_OUT"
echo "</head>" >> "$_OUT"
echo "<body>" >> "$_OUT"
echo '<div style="margin: 0 auto; width:90%;">' >> "$_OUT"
echo "<h2><b>$_TITLE</b></h2>" >> "$_OUT"
if test "$_SHOW" = "1" && ! test -z "$_URL";then echo "My node-id: $_URL<br>" >> "$_OUT";fi
for DDD in $(seq 0 $_DAYS );do _DATELIST="$_DATELIST "$(date +'%m.%d' -d "@$(($(date +%s) - $((86400 * $DDD))))")":\\d";done
_DATELIST="$_DATELIST $_EXTRA"
_COMMENTS=$(ag --filename --nonumbers --noheading "^\d\d\.\d\d:\d ($(echo "$_DATELIST" | sed -e "s/ /|/g")) @.................................." itp-files/*.itp | sed -e "s/^itp-files\///" -e "s/-..................................\.itp//" -e "s/:/ /" -e "s/\\$/\&#36;/g" -e "s/\*/\&#42;/g" | tr '\n' '\\' )
_POSTS=$(ag --filename --nonumbers --noheading "^($(echo "$_DATELIST" | sed -e "s/ /|/g")) " $_FILELIST | grep -E -v "^itp-files/[0-9A-Za-z_]{1,12}-[0-9A-Za-z]{34}\.itp:[[:digit:]][[:digit:]]\.[[:digit:]][[:digit:]]:[[:digit:]] [[:digit:]][[:digit:]]\.[[:digit:]][[:digit:]]:[[:digit:]] @"| sed -e "s/\\$/\&#36;/g" -e "s/\*/\&#42;/g" |  tr '\n' '\\')
for _DATE in $_DATELIST;do
    echo "$_POSTS" | tr '\\' '\n' | ag "^itp-files/[0-9A-Za-z_]{1,12}-[0-9A-Za-z]{34}\.itp:$_DATE" |
    while IFS= read -r _LINE;do
      _FILENAME=${_LINE%%:*}
      _LINE=${_LINE#*:}
      _ALIAS=${_FILENAME##*/};_ALIAS=${_ALIAS%%-*}
      _ID=${_FILENAME##*-};_ID=${_ID%%.*}
      _FOREIGN_URL="$(ag --nonumbers -o 'url1=.*\.[A-za-z0-9]*' "$_FILENAME" || echo "NO_URL1")";_FOREIGN_URL="${_FOREIGN_URL##*=}"
      _LINE=$(echo "$_LINE" | sed -e "s/\\$/\&#36;/g" -e "s/\*/\&#42;/g" -e "s@<download=@<download=$_FOREIGN_URL/@g" -e "s@<plugin=@<plugin=$_FOREIGN_URL/@g" -e "s/</\&lt;/g" -e "s/>/\&gt;/g")
      echo "<hr><b>[$_ALIAS]</b> $_LINE<br>" >> "$_OUT"
      echo "$_COMMENTS" | tr '\\' '\n' | ag "^[[:alpha:]]* \d\d\.\d\d:\d ${_LINE%% *} @$_ID" | sort -k2 -n -t "." | sed -e "s@<download=@<download=$_FOREIGN_URL/@g" -e "s@<plugin=@<plugin=$_FOREIGN_URL/@g"  -e "s/</\&lt;/g" -e "s/>/\&gt;/g" -e "s/^[[:digit:]][[:digit:]]\.[[:digit:]][[:digit:]]:[[:digit:]]* //" |
      while IFS= read -r LLL;do
        _C_ALIAS=$(echo "$LLL" | awk '{print $1}')
        LLL=${LLL#* }
        #echo $LLL|ag '.'
        echo "<br><div style=\"margin: 0 auto; width:94%;\">&#x2022;[$_C_ALIAS] $(echo $LLL | sed -e 's/ [[:digit:]][[:digit:]]\.[[:digit:]][[:digit:]]:[[:digit:]]* @.................................. / /' )</div>" >> "$_OUT"
      done
    done
done
_COMMENTS=;_POSTS=;_FILELIST=;_DATELIST=
echo "  II special characters"
sed -i -e "s/ü/\&uuml;/g" -e "s/ä/\&auml;/g" -e "s/ö/\&ouml;/g" -e "s/Ü/\&Uuml;/g" -e "s/Ä/\&Auml;/g" -e "s/Ö/\&Ouml;/g" -e "s/ß/\&szlig;/g" "$_OUT"

echo "  II making GK-url-tags clickable"
__SC(){
ag -o "\&lt;plugin=[:a-zA-Z0-9._\-/%]*\&gt;|\&lt;download=[:a-zA-Z0-9._\-%/]*\&gt;|\&lt;img=[:()a-zA-Z0-9._\-/%?=]*\&gt;|\&lt;url=(http|https)://[:()a-zA-Z0-9._\-/%?=&]*\&gt;" "$_OUT" |
while IFS= read LLL;do
  LLL=${LLL##*&lt;};LLL=${LLL%%&gt;*}
  if test "${LLL%%=*}" = "download";then
    echo " -e \"s@\&lt;$LLL\&gt;@<a href='${LLL#*=}'>\&lt;$LLL\&gt;</a>@g\""
  elif test "${LLL%%=*}" = "plugin";then
    echo " -e \"s@\&lt;$LLL\&gt;@<a href='${LLL#*=}'>\&lt;$LLL\&gt;</a>@g\""
  elif test "${LLL%%=*}" = "img";then
    echo " -e \"s@\&lt;$LLL\&gt;@<br><div><a href='${LLL#*=}'><img style='max-width:100%;max-height:800px' src='${LLL#*=}'></a></div>@g\""
  elif test "${LLL%%=*}" = "url";then
    AAA=$(echo "$LLL" | sed 's/\&/<<<!>>>/g')
    echo " -e \"s@\&lt;${LLL}\&gt;@<a href='${AAA#*=}'>\&lt;$AAA\&gt;</a>@g\""
  fi
done
}
_SED_CMD=$(__SC)
if ! test -z "$_SED_CMD";then eval "sed -i "$_SED_CMD" $_OUT";sed -i "s@<<<!>>>@\&@g" "$_OUT";fi
if ! test -z "_$INC" && test -f "$_INC";then cat "$_INC" >> "$_OUT";fi
echo "</div>" >> "$_OUT"
echo "</body><html>" >> "$_OUT"

