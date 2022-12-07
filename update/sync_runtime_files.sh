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
    echo -n "  ?? there seems to be no new version - update anyway? (Y/n) [Return] >"
    read BUF
    if test "$BUF" != "Y";then exit 1;fi
  fi
  echo "  ## unpacking"
  rm -f "$UPD_NAME" Goldkarpfen/VERSION* && tar -xf "../archives/$UPD_NAME" && cp -a Goldkarpfen/update/sync_runtime_files.sh . || exit 1
else
  set -e
  rm -f ../VERSION* ; mkdir -p ../DOC ../plugins ; cd Goldkarpfen
  for T_FILE in Goldkarpfen.sh plugins/update.sh include.sh sync-from-nodes.sh update-archive-date.sh check-dependencies.sh itp-check.sh keys.sh sign.sh check-sign.sh check-dates.sh prune-month.sh plugins/migration-warning.sh plugins/nodes.sh plugins/plugin.sh start-hidden-service.py start-services.sh stop-hidden-service.py stop-services.sh help-en.dat update-provider.inc.sh .Goldkarpfen.start.sh .Goldkarpfen.exit.sh new-account.sh DOC/address_migration.txt LICENSE README DOC/ITP-DEFINITION;do
    if ! cmp "$T_FILE" "../../$T_FILE" > /dev/null 2>&1;then
      cp -a --verbose "$T_FILE" "../../$T_FILE"
    fi
  done
  cp -a --verbose VERSION-* ../../
  cd .. ; cd ..
  #CONFIG MIGRATION
  if test "$VERSION_LOCAL" -lt 208;then echo; echo "  II server.dat format has changed : run [r][A] after restart again" | ag .;fi
  if test -f Goldkarpfen.config;then exit 0;fi
  ls .Goldkarpfen.config.default.sh
  BUF1=$(ag --no-numbers '^OWN_STREAM' .Goldkarpfen.config.default.sh | sed 's/^.*\///' | sed 's/".*//')
  BUF2=$(ag --no-numbers '^.*SERVER_PORT' .Goldkarpfen.config.default.sh | sed 's/^.*="//' | sed 's/".*//')
  echo "# itp-file" > Goldkarpfen.config
  echo "$BUF1" >> Goldkarpfen.config
  echo "# SERVER_PORT" >> Goldkarpfen.config
  echo "$BUF2" >> Goldkarpfen.config
fi