#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
if ! test -f $(basename "$0");then echo "  EE run this script in its folder";exit 1;fi
. ../update-provider.inc.sh || exit 1

VERSION_LOCAL=$(ls ../VERSION-* | tail -n 1);VERSION_LOCAL=$(printf "%i" "${VERSION_LOCAL#../VERSION-2.1.}")

if test "$1" = "--first-run";then
  VERSION_ARCHIVES=$(tar -tf "../archives/$UPD_NAME"| ag "VERSION" | awk -F "." '{print $3}')
  if test -z "$VERSION_ARCHIVES";then exit 1;fi
  echo "  II tarball version: "$DATE_ARCHIVES"  "$VERSION_ARCHIVES
  echo "  II local version  : "$DATE_LOCAL"  "$VERSION_LOCAL
  if ! test "$VERSION_ARCHIVES" -gt "$VERSION_LOCAL";then
    echo -n "  ?? there seems to be no new version - update anyway? Y/[N] [Return] >"
    read BUF
    if test "$BUF" != "Y";then exit 1;fi
  fi
  echo "  ## unpacking"
  rm -f "$UPD_NAME" Goldkarpfen/VERSION* && tar -xf "../archives/$UPD_NAME" && cp -a Goldkarpfen/update/sync_runtime_files.sh srf.tmp || exit 1
else
  set -e
  rm -f ../VERSION* ; mkdir -p ../DOC ../plugins ../.keys ../archives/share; cd Goldkarpfen
  for T_FILE in Goldkarpfen.sh plugins/update.sh include.sh sync-from-nodes.sh update-archive-date.sh check-dependencies.sh itp-check.sh keys.sh sign.sh check-sign.sh check-dates.sh prune-month.sh plugins/migration-warning.sh plugins/nodes.sh plugins/plugin.sh start-hidden-service.py start-services.sh stop-hidden-service.py stop-services.sh help-en.dat .Goldkarpfen.start.sh .Goldkarpfen.exit.sh new-account.sh .keys/test.pem DOC/address_migration.txt archives/share/gki.sh LICENSE README;do
    if ! cmp "$T_FILE" "../../$T_FILE" > /dev/null 2>&1;then
      cp -a -v "$T_FILE" "../../$T_FILE"
    fi
  done
  cp -a -v VERSION-* ../../
fi