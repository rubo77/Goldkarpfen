#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
if ! test -f $(basename $0);then echo "  EE run this script in its folder.";exit;fi
. ../include.sh
. ../update-provider.inc.sh

__SYNC(){
  rm ../VERSION*
  mkdir -p ../DOC ../plugins
  cd Goldkarpfen
  for T_FILE in DOC/address_migration.txt DOC/ITP-DEFINITION itp-check.sh Goldkarpfen.sh include.sh keys.sh sign.sh check-sign.sh check-dates.sh new-account.sh prune-month.sh plugins/migration-warning.sh plugins/nodes.sh plugins/plugin.sh plugins/update.sh sync-from-nodes.sh update-archive-date.sh start-hidden-service.py start-services.sh stop-hidden-service.py stop-services.sh help-en.dat check-dependencies.sh LICENSE README update-provider.inc.sh .Goldkarpfen.start.sh .Goldkarpfen.exit.sh;do
    if ! cmp "$T_FILE" "../../$T_FILE" > /dev/null 2>&1;then
      echo -n "  ## updating" ; echo " $T_FILE"
      cp -a "$T_FILE" "../../$T_FILE"
    fi
  done
  cp -a VERSION-* ../../
  cd ..
}

if test "$1" = "--first-run";then
  VERSION_ARCHIVES=$(tar -tf ../archives/"$UPD_NAME"| ag "VERSION" |  __collum 3 ".")
  VERSION_LOCAL=$(ls ../VERSION-* | tail -n 1);VERSION_LOCAL=$(printf "%i" ${VERSION_LOCAL#../VERSION-2.1.})
  if test -z "$VERSION_ARCHIVES";then exit 1;fi
  echo "  II tarball version: "$DATE_ARCHIVES"  "$VERSION_ARCHIVES
  echo "  II local version  : "$DATE_LOCAL"  "$VERSION_LOCAL
  if ! test "$VERSION_ARCHIVES" -gt "$VERSION_LOCAL";then
    echo -n "  ?? there seems to be no new version - update anyway? (Y/n) [Return] >"
    read BUF
    if test "$BUF" != "Y";then exit 1;fi
  else
    echo -n "  ?? new version available - upgrade now? (y/n) [Return] >"
    read BUF
    if test "$BUF" != "y";then exit 1;fi
  fi
  rm -f "$UPD_NAME" Goldkarpfen/VERSION*
  if tar -xvf "../archives/$UPD_NAME" > /dev/null;then
    cp -a Goldkarpfen/update/sync_runtime_files.sh .
    exit 0
  else
    exit 1
  fi
else
  VERSION_LOCAL=$(ls ../VERSION-* | tail -n 1);VERSION_LOCAL=$(printf "%i" ${VERSION_LOCAL#../VERSION-2.1.})
  __SYNC
  #CONFIG MIGRATION
  cd ..
  if ! test -f Goldkarpfen.config;then
    BUF1=$(ag --no-numbers '^OWN_STREAM' .Goldkarpfen.config.default.sh | sed 's/^.*\///' | sed 's/".*//')
    BUF2=$(ag --no-numbers '^.*SERVER_PORT' .Goldkarpfen.config.default.sh | sed 's/^.*="//' | sed 's/".*//')
    echo "# itp-file" > Goldkarpfen.config
    echo "$BUF1" >> Goldkarpfen.config
    echo "# SERVER_PORT" >> Goldkarpfen.config
    echo "$BUF2" >> Goldkarpfen.config
  fi
  if test -f .Goldkarpfen.config.default.sh;then echo; echo "  II .Goldkarpfen.config.default.sh is obsolete. you can delete it" | ag .;fi
  if test "$VERSION_LOCAL" -lt 208;then echo; echo "  II server.dat format has changed : run [r][A] after restart again" | ag .;fi
fi
