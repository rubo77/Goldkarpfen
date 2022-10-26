#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
if ! test -f $(basename $0);then echo "  EE run this script in its folder.";exit;fi
. ../include.sh
. ../update-provider.inc.sh

__SYNC(){
  rm ../VERSION*
  for T_FILE in Goldkarpfen/DOC Goldkarpfen/itp-check.sh Goldkarpfen/Goldkarpfen.sh Goldkarpfen/include.sh Goldkarpfen/keys.sh Goldkarpfen/sign.sh Goldkarpfen/check-sign.sh Goldkarpfen/check-dates.sh Goldkarpfen/new-account.sh Goldkarpfen/prune-month.sh Goldkarpfen/plugins Goldkarpfen/sync-from-nodes.sh Goldkarpfen/update-archive-date.sh Goldkarpfen/start-hidden-service.py Goldkarpfen/start-services.sh Goldkarpfen/stop-hidden-service.py Goldkarpfen/stop-services.sh Goldkarpfen/help-en.dat Goldkarpfen/check-dependencies.sh Goldkarpfen/check-dependencies-ubuntu.sh Goldkarpfen/LICENSE Goldkarpfen/VERSION* Goldkarpfen/README Goldkarpfen/update-provider.inc.sh Goldkarpfen/.Goldkarpfen.start.sh Goldkarpfen/.Goldkarpfen.exit.sh;do
    cp -a $T_FILE ..
  done
}

if test "$1" = "--first-run";then
  VERSION_ARCHIVES=$(tar -tvf ../archives/"$UPD_NAME"| ag "VERSION" | sed "s/.*\.//")
  VERSION_LOCAL=$(ls ../VERSION-* | tail -n 1 | sed "s/.*\.//")
  if test -z "$VERSION_ARCHIVES";then exit 1;fi
  echo "  II tarball version: "$DATE_ARCHIVES"  "$VERSION_ARCHIVES
  echo "  II local version  : "$DATE_LOCAL"  "$VERSION_LOCAL
  cd ..
  if ! test "$VERSION_ARCHIVES" -gt "$VERSION_LOCAL";then
    echo -n "  ?? there seems to be no new version - update anyway? (Y/n) [Return] >"
    read BUF
    if test "$BUF" != "Y";then exit 1;fi
  else
    echo -n "  ?? new version available - upgrade now? (y/n) [Return] >"
    read BUF
    if test "$BUF" != "y";then exit 1;fi
  fi
  cd update
  rm -Rf ./Goldkarpfen/
  cp -a ../archives/"$UPD_NAME" .
  if tar xfv "$UPD_NAME" > /dev/null;then
    cp -a Goldkarpfen/update/sync_runtime_files.sh .
    exit 0
  else
    exit 1
  fi
else
  __SYNC > /dev/null
  echo "  ## updating"
  #CONFIG MIGRATION
  cd ..
  if ! test -f Goldkarpfen.config;then
    BUF1=$(ag --no-numbers '^OWN_STREAM' .Goldkarpfen.config.default.sh | sed 's/^.*\///' | sed 's/".*//')
    BUF2=$(ag --no-numbers '^.*SERVER_PORT' .Goldkarpfen.config.default.sh | sed 's/^.*="//' | sed 's/".*//')
    echo "# itp-file" > Goldkarpfen.config
    echo "$BUF1" >> Goldkarpfen.config
    echo "# server-port" >> Goldkarpfen.config
    echo "$BUF2" >> Goldkarpfen.config
  fi
  if test -f .Goldkarpfen.config.default.sh;then echo; echo "  II .Goldkarpfen.config.default.sh is obsolete. you can delete it" | ag .;fi
fi
