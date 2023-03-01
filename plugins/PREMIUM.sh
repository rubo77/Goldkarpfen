#GPL-3 - See LICENSE file for copyright and license details.
#V0.5
#GKdev-1FHDi5veznUojyHaZQ9wv5dwj5aqZmXYGg.itp
__USER_PREMIUM(){
  . ./update-provider.inc.sh
  echo "  II PREMIUM check ..."
  if ! test "$UPD_NAME" = "Goldkarpfen-termux.tar.gz";then
    printf "  II PREMIUM-versions are only compatible with Goldkarpfen-termux.tar.gz\n"
    return
  fi
  if ! test -f "itp-files/GKdev-1FHDi5veznUojyHaZQ9wv5dwj5aqZmXYGg.itp";then
    echo "  II get GKdev-1FHDi5veznUojyHaZQ9wv5dwj5aqZmXYGg.itp to veryfiy your premium version"
    return
  fi
  if ! ./check-sign.sh "itp-files/GKdev-1FHDi5veznUojyHaZQ9wv5dwj5aqZmXYGg.itp" > /dev/null 2>&1;then
    echo "  EE could not verify GKdev stream"
    return
  fi
  if ! ag "^\d\d\.\d\d:\d \d\d\.\d\d:\d @1FHDi5veznUojyHaZQ9wv5dwj5aqZmXYGg <plugin=share/PREMIUM.sh> #GKdev-1FHDi5veznUojyHaZQ9wv5dwj5aqZmXYGg.itp #V0.5" itp-files/GKdev-1FHDi5veznUojyHaZQ9wv5dwj5aqZmXYGg.itp > /dev/null;then
    echo "  II an upgrade for your PREMUIM plugin is available."
    echo "  II update your PREMIUM plugin first."
    return
  fi
  if ! ./check-sign.sh "itp-files/$OWN_ALIAS-$OWN_ADDR.itp" > /dev/null 2>&1;then echo "  EE could not verify your own address";return;fi
  if ! ag "^00.07:\d 00.01:7 @1FHDi5veznUojyHaZQ9wv5dwj5aqZmXYGg $OWN_ADDR .*" itp-files/GKdev-1FHDi5veznUojyHaZQ9wv5dwj5aqZmXYGg.itp > /dev/null;then
    echo "  II your Goldkarpfen is : standard"
  else
    set -- "$(ls VERSION-* | tail -n 1)"
    if test -z "$1";then echo "  EE VERSION file not found (solution : run [r][U] to force update)";return;fi
    if ! ag "^PREMIUM : $OWN_ALIAS$" "$1" > /dev/null;then
      printf -- "$(head -n 1 "$1")\nPREMIUM\n$OWN_ADDR\n" > "$1"
    fi
    if ! test "$(ag --no-numbers "^00.07:\d 00.01:7 @1FHDi5veznUojyHaZQ9wv5dwj5aqZmXYGg $OWN_ADDR .*" itp-files/GKdev-1FHDi5veznUojyHaZQ9wv5dwj5aqZmXYGg.itp | __collum 5)" = "$(cat plugins/PREMIUM.sh "$1" Goldkarpfen.sh plugins/update.sh include.sh sync-from-nodes.sh update-archive-date.sh check-dependencies.sh itp-check.sh keys.sh sign.sh check-sign.sh check-dates.sh prune-month.sh plugins/migration-warning.sh plugins/nodes.sh plugins/plugin.sh start-hidden-service.py start-services.sh stop-hidden-service.py stop-services.sh help-en.dat .Goldkarpfen.start.sh .Goldkarpfen.exit.sh new-account.sh DOC/address_migration.txt LICENSE README | sha512sum | awk '{print $1}')";then
      echo "  EE your premium version could not be verified !"
      echo "  II be sure to have the latest official GKdev-stream"
      echo "  II be sure to have the latest Goldkarpfen-termux.tar.gz"
    else
      echo "  II your Goldkarpfen is : ***PREMIUM***" | ag "."
    fi
  fi
}

USER_HOOK_START="__USER_PREMIUM ; $USER_HOOK_START"
