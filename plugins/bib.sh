#GPL-3 - See LICENSE file for copyright and license details.
#V0.6
#Goldkarpfen-1JULSJ5Nnba9So48zi21rpfTuZ3tqNRaFB.itp
USER_PLUGINS_MENU="[B]-bib:__USER_BIB $USER_PLUGINS_MENU"
__USER_BIB(){
BIB_BIBLE=$(ls archives/share/BIB-* 2> /dev/null| head -n 1)
if test -z "$BIB_BIBLE"; then echo "No bib-file found."; return;fi
# TERM_COLLUMS
set "$(echo $(tput cols) - 5 | bc)"
while true;do
  echo
  echo "##### bib menu  BIB_MARK:$BIB_MARK  $(basename $BIB_BIBLE)"
  echo "[/]-search [v]-view [c]-compare [b]-choose_bible [i]-info [q]-exit_bib"
  $GK_READ_CMD T_CHAR
  echo
  case "$T_CHAR" in
    /)
      echo " fuzzy search for WORD - [Return] to fuzzy search all"
      echo -n "WORD: "
      read T_BUF1
      T_BUF=$(ag --nonumbers "^.*\..*:.*$T_BUF1.*" "$BIB_BIBLE" | pipe_if_not_empty "$GK_FZF_CMD")
      if test -z "$T_BUF"; then 
        echo "Nothing found - not changing the mark"
      else
        BIB_MARK=$(echo "$T_BUF" | __collum 1)
      fi
    ;;
    v)
      fold  -w "$1" -s "$BIB_BIBLE" | less -p"^$BIB_MARK"
    ;;
    i)
      echo "We are using the englisch book abbrevs (Gen,Deut...) so you can easily use the text files of BIB_BIBLE4U."
      echo "Make sure the prefix of the files is \"BIB-\""
    ;;
    c)
      if test -z "$BIB_MARK";then
        echo "No mark selected - search first.";
      else
        ag "^$BIB_MARK " archives/share/BIB-* | fold -w "$1" -s
      fi
    ;;
    b)
      BIB_BIBLE=$(ls archives/share/BIB-* | pipe_if_not_empty "$GK_FZF_CMD")
      if test -z "$BIB_BIBLE"; then echo "No bib-file found."; break;fi
      ;;
    q) return ;;
  esac
done
}
