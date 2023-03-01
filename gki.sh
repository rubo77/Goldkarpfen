#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
#V0.37
if ! test -f $(basename "$0");then echo "  EE run this script in its folder";exit 1;fi
if ! test "$(pwd)" = "$HOME";then echo "  EE gki.sh is meant to be run in the home folder.";exit 1;fi
if test "$1" = "-a";then
  echo "  II ios(ish) mode not finished yet"; exit
  INSTALL_MODE="ish";shift
  #__TOR_DATA_DIR="/data/data/com.termux/files/usr/var/service/tor/"
  #__TOR_CONFIG_DIR="/data/data/com.termux/files/usr/etc/tor/"
else
  __TOR_DATA_DIR="/data/data/com.termux/files/usr/var/service/tor/"
  __TOR_CONFIG_DIR="/data/data/com.termux/files/usr/etc/tor/"
fi
if test "$1" = "--delete";then
if ! test -d Goldkarpfen;then echo "no Goldkarpfen folder found!";exit;fi
echo "  WW this command will change torrc and tor-var-folder" | ag "."
echo "  WW use this command ONLY (!)" | ag "."
echo "  WW if you haven't configured your torrc manually" | ag "."
echo "Proceed ? Y/[N]"
read T_CONFIRM
if test "$T_CONFIRM" = "Y";then
  if ! test -f Goldkarpfen/Goldkarpfen.config;then echo "ERROR : cannot open Goldkarpfen/Goldkarpfen.config";exit;fi
    T_BUF_KEY=$(sed -n '2 p' Goldkarpfen/Goldkarpfen.config | sed -e 's/^.*-//' -e 's/\.itp$//')
    T_BUF_PORT=$(sed -n '4 p' Goldkarpfen/Goldkarpfen.config)
    if echo "$T_BUF_KEY" | ag "[0-9A-Za-z]{34}" > /dev/null;then
      killall tor ; sleep 1
      rm -rf "$__TOR_DATA_DIR$T_BUF_KEY"
      sed -i "/^HiddenService.*$T_BUF_KEY.*$/d" ""$__TOR_CONFIG_DIR"torrc"
      sed -i "/^HiddenService.*$T_BUF_PORT$/d" ""$__TOR_CONFIG_DIR"torrc"
      sed -i "/^sh start-gk\.sh$/d" .profile
      if ag "^tor|^i2pd" .profile > /dev/null;then echo "tor/i2pd service starter is/are still in .profile";fi
      rm -rf Goldkarpfen/
      rm -rf Goldkarpfen-termux.tar.gz
      echo
      if ! pidof tor > /dev/null;then eval "nohup tor --quiet &";fi
    else
      echo "could not extract hidden-service-dir from Goldkarpfen.config"
    fi
  fi
  exit
fi
T_BUF=
if ! test -d Goldkarpfen/ || ! test -f Goldkarpfen/Goldkarpfen.config;then
   T_BUF="$T_BUF  II gki [+] GK base\n"
fi
if ! grep "^HiddenServiceDir" ""$__TOR_CONFIG_DIR"torrc" > /dev/null 2>&1;then
   T_BUF="$T_BUF  II gki [+] service entry to torrc\n"
fi
if ! grep "^export EDITOR" .mkshrc > /dev/null 2>&1;then
  T_BUF="$T_BUF  II gki [+] EDITOR entry to .mkshrc\n"
fi
if ! grep "^export EDITOR" .bashrc > /dev/null 2>&1;then
  T_BUF="$T_BUF  II gki [+] EDITOR entry to .bashrc\n"
fi
if ! test -f ~/.i2pd/tunnels.conf && command -v i2pd > /dev/null;then
  T_BUF="$T_BUF  II gki [+] i2pd-tunnel\n"
fi
if ! test -z "$T_BUF";then
  printf "$T_BUF" | ag "."
  echo "  ?? Start gki ? Y/[N]"
  read T_CONFIRM
  if ! test "$T_CONFIRM" = "Y";then exit;fi
fi
if ! command -v tor > /dev/null 2>&1;then pkg install tor || exit;fi
if ! command -v curl > /dev/null 2>&1;then pkg install curl || exit;fi
if ! pidof tor > /dev/null;then eval "nohup tor --quiet &";fi
if ! test -d Goldkarpfen || ! test -f Goldkarpfen/Goldkarpfen.config;then
  echo "pls wait ..."
  sleep 6
  T_BUF2="Goldkarpfen-termux.tar.gz"
  if echo "$1" | grep "^https://gitlab.com" > /dev/null;then
    T_BUF1=
    if ! test -z "$2";then T_BUF2=$2;else T_BUF2="Goldkarpfen-release_277_termux.tar.gz";fi
  elif echo "$1" | grep "[A-Za-z0-9.]*\.i2p" > /dev/null;then
    T_BUF1="--proxy localhost:4444"
  elif echo "$1" | grep -E "[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}" > /dev/null;then
    T_BUF1=
  else
    T_BUF1="--proxy socks5://127.0.0.1:9050 --socks5-hostname 127.0.0.1:9050"
  fi
  if echo "$1" | ag "^gopher://" > /dev/null;then
    if ! curl -f $T_BUF1 "$1/\/$T_BUF2" -o "$T_BUF2"; then exit;fi
  else
    if ! curl -f $T_BUF1 "$1/$T_BUF2" -o "$T_BUF2"; then exit;fi
  fi
  T_BUF3=$(tar -tf "$T_BUF2" | head -n 1)
  tar -xf "$T_BUF2" || exit
  if ! test "$T_BUF3" = "Goldkarpfen/";then mv "$T_BUF3" Goldkarpfen || exit ;fi
  if test "$INSTALL_MODE" = "ish";then
    apk add mksh darkhttpd fzy openssl silversearch-ag ncurses
    #apk add mksh darkhttpd fzy openssl silversearch-ag ncurses libqrencode
  else
    pkg install mksh file fzy openssl-tool silversearcher-ag bc darkhttpd iproute2 vim ncurses-utils libqrencode
  fi
  cd Goldkarpfen || exit
  if test "$(./check-dependencies.sh | tail -n 1)" = "ERROR";then exit;fi
  while ! ./new-account.sh;do
    echo "  EE error"
    echo "  ?? try again ? [y]/n"
    read T_CONFIRM
    if test "$T_CONFIRM" = "n";then exit;fi
    rm -rf .keys/*
  done
  cd ..
else
  echo "  II Goldkarpfen exists"
  echo "  II to reinstall erase old one first:"
  printf "  sh gki.sh --delete\n"
fi
if ! grep "^export EDITOR" .bashrc > /dev/null 2>&1;then
  echo "export EDITOR=nano" >> .bashrc || exit
fi
if ! grep "^export EDITOR" .mkshrc > /dev/null 2>&1;then
  echo "export EDITOR=nano" >> .mkshrc || exit
fi
T_BUF_KEY=$(sed -n '2 p' Goldkarpfen/Goldkarpfen.config | sed -e 's/^.*-//' -e 's/\.itp$//')
T_BUF_PORT=$(sed -n '4 p' Goldkarpfen/Goldkarpfen.config)
if ! echo "$T_BUF_KEY" | ag "[0-9A-Za-z]{34}$" > /dev/null;then
  echo
  echo "  EE Goldkarpfen/Goldkarpfen.config itp-file entry seems to be wrong!"
  echo "  EE cannot configure HiddenService"
  echo
elif ! echo "$T_BUF_PORT" | ag "^[[:digit:]]{1,5}$" > /dev/null;then
  echo
  echo "  EE Goldkarpfen/Goldkarpfen.config SERVER_PORT entry seems to be wrong!"
  echo "  EE cannot configure HiddenService"
  echo
else
  if ! grep "^HiddenServiceDir" ""$__TOR_CONFIG_DIR"torrc" > /dev/null 2>&1;then
    killall tor ; sleep 1
    echo "HiddenServiceDir $__TOR_DATA_DIR$T_BUF_KEY/" >> ""$__TOR_CONFIG_DIR"torrc"
    echo "HiddenServicePort 80 127.0.0.1:$T_BUF_PORT" >> ""$__TOR_CONFIG_DIR"torrc"
    if ! pidof tor > /dev/null;then eval "nohup tor --quiet &";fi
    echo "pls wait ..."
    sleep 6
  else
    echo "  II hidden service is already configured"
  fi
fi
if ! test -f ~/.i2pd/tunnels.conf && command -v i2pd > /dev/null;then
  mkdir -p ~/.i2pd
  killall i2pd 2> /dev/null
  echo "[Goldkarpfen]" >  ~/.i2pd/tunnels.conf
  echo "type = http" >> ~/.i2pd/tunnels.conf
  echo "host = 127.0.0.1" >> ~/.i2pd/tunnels.conf
  echo "port = $T_BUF_PORT" >> ~/.i2pd/tunnels.conf
  echo "keys = Goldkarpfen.dat" >> ~/.i2pd/tunnels.conf
  if ! pidof i2pd > /dev/null;then eval "nohup i2pd --daemon --loglevel=none";fi
else
  echo "  II .i2pd/tunnels.conf already exists"
fi

printf '#!/bin/sh\nif ! pidof tor > /dev/null;then eval "nohup tor --quiet &";fi\nif ! pidof i2pd > /dev/null && command -v i2pd > /dev/null;then eval "nohup i2pd --daemon --loglevel=none &";fi\nif test -z "$EDITOR";then export EDITOR=nano;fi\ncd Goldkarpfen\nif command -v mksh > /dev/null;then mksh Goldkarpfen.sh;else bash Goldkarpfen.sh;fi' > start-gk.sh || exit
if ! grep "sh start-gk.sh" .profile > /dev/null 2>&1;then
  echo
  echo "  ?? autostart Goldkarpfen? [y]/n" | ag .
  echo "  II adds an entry to .profile :"
  echo "  sh start-gk.sh"
  read T_CONFIRM
  if ! test "$T_CONFIRM" = "n";then
    echo "sh start-gk.sh" >> .profile
  fi
fi
if pidof tor > /dev/null;then
  echo "COPY YOUR ONION-HOSTNAME : your onion hostname is :"
  echo -n "http://" | ag "."
  cat "$__TOR_DATA_DIR$T_BUF_KEY/hostname" | ag "."
fi
if pidof i2pd > /dev/null;then
  if curl -s http://127.0.0.1:7070/?page=i2p_tunnels | ag Goldkarpfen > /dev/null;then
    echo "COPY YOUR I2P-HOSTNAME :"
    echo -n "http://" | ag "."
    curl -s http://127.0.0.1:7070/?page=i2p_tunnels | ag Goldkarpfen | ag -o "[0-9A-Za-z]{1,80}\.b32.i2p"
  fi
fi

mkdir -p Goldkarpfen/archives/share
set -- "$(sed -n '3 p' gki.sh 2> /dev/null)" "$(sed -n '3 p' Goldkarpfen/archives/share/gki.sh 2> /dev/null)"
set -- $(printf "%i" "${1#*.}") $(printf "%i" "${2#*.}")
if test "$1" -gt "$2";then cp gki.sh Goldkarpfen/archives/share;fi
if ! test -f Goldkarpfen/archives/Goldkarpfen-termux.tar.gz;then cp Goldkarpfen-termux.tar.gz Goldkarpfen/archives;fi
echo
printf "  II get your onion or i2p hostname with :\n  sh gki.sh\n"
echo
echo "[ctrl][c] to exit the installer"
echo "(from promp start Goldkarpfen with)"
echo "sh start-gk.sh"
echo
echo "[Return] to start Goldkarpfen" | ag "."
read T_BUF
sh start-gk.sh
