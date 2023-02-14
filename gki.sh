#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
#V0.31
if ! test -f $(basename "$0");then echo "  EE run this script in its folder";exit 1;fi
if ! test "$(pwd)" = "/data/data/com.termux/files/home";then echo "  EE gki.sh is meant to be run in the home folder.";exit 1;fi
if test "$1" = "--delete";then
if ! test -d Goldkarpfen;then echo "no Goldkarpfen folder found!";exit;fi
echo "WARNING : this command will alter your torrc and tor-var-folder" | ag "."
echo "WARNING : use this command ONLY if you haven't configured your tor service manually" | ag "."
echo "Proceed ? (Y/n)"
read T_CONFIRM
if test "$T_CONFIRM" = "Y";then
  if ! test -f Goldkarpfen/Goldkarpfen.config;then echo "ERROR : cannot open Goldkarpfen/Goldkarpfen.config";exit;fi
  T_BUF_KEY=$(sed -n '2 p' Goldkarpfen/Goldkarpfen.config | sed -e 's/^.*-//' -e 's/\.itp$//')
  T_BUF_PORT=$(sed -n '4 p' Goldkarpfen/Goldkarpfen.config)
  if echo "$T_BUF_KEY" | ag "[0-9A-Za-z]{34}" > /dev/null;then
    killall tor ; sleep 1
    rm -rf "/data/data/com.termux/files/usr/var/service/tor/$T_BUF_KEY"
    sed -i "/^HiddenService.*$T_BUF_KEY.*$/d" /data/data/com.termux/files/usr/etc/tor/torrc
    sed -i "/^HiddenService.*$T_BUF_PORT$/d" /data/data/com.termux/files/usr/etc/tor/torrc
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

if ! command -v tor > /dev/null 2>&1;then pkg install tor || exit;fi
if ! command -v curl > /dev/null 2>&1;then pkg install curl || exit;fi
if ! pidof tor > /dev/null;then eval "nohup tor --quiet &";fi
if ! test -d Goldkarpfen;then
  echo "pls wait ..."
  sleep 6
  if echo "$1" | grep "[A-Za-z0-9.]*\.i2p" > /dev/null;then
    T_BUF1="--proxy localhost:4444"
  elif echo "$1" | grep -E "[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}" > /dev/null;then
    T_BUF1=
  else
    T_BUF1="--proxy socks5://127.0.0.1:9050 --socks5-hostname 127.0.0.1:9050"
  fi
  if echo "$1" | ag "^gopher://" > /dev/null;then
    if ! curl -f $T_BUF1 "$1/\/Goldkarpfen-termux.tar.gz" -o Goldkarpfen-termux.tar.gz; then exit;fi
  else
    if ! curl -f $T_BUF1 "$1/Goldkarpfen-termux.tar.gz" -o Goldkarpfen-termux.tar.gz; then exit;fi
  fi
  tar -xf Goldkarpfen-termux.tar.gz
  pkg install file fzy openssl-tool silversearcher-ag bc darkhttpd iproute2 vim ncurses-utils libqrencode
  command -v file fzy openssl ag dc darkhttpd ip xxd tput > /dev/null || exit
  cd Goldkarpfen || exit
  if ! ./new-account.sh;then
    cd ..
    rm -rf Goldkarpfen/
    printf "  ERROR : run again :\n  sh gki.sh\n  (legacy : sh gk-termux-installer.sh)\n"
    exit
  fi
  cd ..
else
  echo "  II there seems to be already a Goldkarpfen directory"
  echo "  II for a new installation erase your old one first:"
  printf "  sh gki.sh --delete\n  (legacy : sh gk-termux-installer.sh --delete)\n"
fi
if ! grep "^export EDITOR" .bashrc > /dev/null 2>&1;then
  echo "export EDITOR=nano" >> .bashrc || exit
else
  echo "  II editor var already set in .bashrc"
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
  if ! grep "^HiddenServiceDir" /data/data/com.termux/files/usr/etc/tor/torrc > /dev/null 2>&1;then
    killall tor ; sleep 1
    echo "HiddenServiceDir /data/data/com.termux/files/usr/var/service/tor/$T_BUF_KEY/" >> /data/data/com.termux/files/usr/etc/tor/torrc
    echo "HiddenServicePort 80 127.0.0.1:$T_BUF_PORT" >> /data/data/com.termux/files/usr/etc/tor/torrc
    if ! pidof tor > /dev/null;then eval "nohup tor --quiet &";fi
    echo "pls wait ..."
    sleep 6
  else
    echo "  II hidden service is already configured"
  fi
fi
if ! test -f ~/.i2pd/tunnels.conf && command -v i2pd > /dev/null;then
  mkdir -p ~/.i2pd
  killall i2pd
  echo "[Goldkarpfen]" >  ~/.i2pd/tunnels.conf
  echo "type = http" >> ~/.i2pd/tunnels.conf
  echo "host = 127.0.0.1" >> ~/.i2pd/tunnels.conf
  echo "port = $T_BUF_PORT" >> ~/.i2pd/tunnels.conf
  echo "keys = Goldkarpfen.dat" >> ~/.i2pd/tunnels.conf
  if ! pidof i2pd > /dev/null;then eval "nohup i2pd --daemon --loglevel=none &";fi
else
  echo "  II .i2pd/tunnels.conf already exists"
fi

printf '#!/bin/sh\nif ! pidof tor > /dev/null;then eval "nohup tor --quiet &";fi\nif ! pidof i2pd > /dev/null && command -v i2pd > /dev/null;then eval "nohup i2pd --daemon --loglevel=none &";fi\nif test -z "$EDITOR";then export EDITOR=nano;fi\ncd Goldkarpfen\nbash Goldkarpfen.sh' > start-gk.sh || exit
if ! grep "^sh start-gk.sh" .profile > /dev/null 2>&1;then
  echo
  echo "enable autostart Goldkarpfen (will change .profile)? y/n"
  echo "(if you skip this step you need to start Goldkarpfen with : sh start-gk.sh)"
  read T_CONFIRM
  if test "$T_CONFIRM" = "y";then
    echo "sh start-gk.sh" >> .profile
  fi
fi
if pidof tor > /dev/null;then
  echo "COPY YOUR ONION-HOSTNAME : your onion hostname is :"
  echo -n "http://" | ag "."
  cat "/data/data/com.termux/files/usr/var/service/tor/$T_BUF_KEY/hostname" | ag "."
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
printf "  II get your onion or i2p hostname with :\n  sh gki.sh\n  (legacy : sh gk-termux-installer.sh)\n"
echo
echo "[Return] to start Goldkarpfen"
echo "[ctrl][c] to exit"
echo "from promp start with : sh start-gk.sh"
read T_BUF
sh start-gk.sh
