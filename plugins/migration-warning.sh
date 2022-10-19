#GPL-3 - See LICENSE file for copyright and license details.
__MIGRATION(){
  T_BUF1=$OWN_ADDR
  T_BUF2=$(./keys.sh .keys/pub.pem 2> /dev/null)
  if ! test "$T_BUF2" = "$T_BUF1" && test "${T_BUF2#0}" = "${T_BUF1#1}";then
    echo
    echo "Warning: you are using a deprecated key_addr - the support for it will end at some point." | ag "."
    echo "HOW TO MIGRATE:"
    echo "Stop Goldkarpfen; open a terminal an go into your Goldkarpfen folder"
    echo
    echo "  cd itp-files"
    echo "  cp $OWN_ALIAS-$T_BUF1.itp $OWN_ALIAS-$T_BUF2.itp"
    echo "  sha512sum $OWN_ALIAS-$T_BUF2.itp > $OWN_ALIAS-$T_BUF2.itp.sha512sum"
    echo "  cd .."
    echo "  ./sign.sh itp-files/$OWN_ALIAS-$T_BUF2.sha512sum"
    echo
    echo "Start Goldkarpfen and edit [!] your old itp-file and remove all posts and comments; after that add a post with: \"delete this itp-channel and blacklist it.\""
    echo "Stop Goldkarpfen and edit your Goldkarpfen.config and change the second line to: $OWN_ALIAS-$T_BUF2.itp"
    echo "If you are using tor: rename your tor-service dir"
    echo
    echo "  sudo mv /var/lib/tor/$T_BUF1 /var/lib/tor/$T_BUF2"
    echo
    echo "Start Goldkarpfen and archive your new itp-stream and don’t forget to adapt your aliases."
    echo "Seed your 'marked-for-deletion-stream' for some time and then delete it."
fi
}
__HOOK_START(){
  __MIGRATION
}
