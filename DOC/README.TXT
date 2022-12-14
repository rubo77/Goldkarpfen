### ABOUT
Goldkarpfen is a pure p2p communication system without any central authority.

### INSTALLATION AND FIRST START
1. Your EDITOR enviroment variable needs to be set similar to this (add this to ~/.bashrc or ~/.mkshrc or alike):
  export EDITOR="nano"

2. Install the basic dependencies:
ag (the-silver-searcher), fzy (or fzf), libressl/openssl, xxd from vim/xxd-standalone

Choose a method for hosting: 3a. ONION-SHARING _or_ 3b. i2p-SHARING

3a. ONION-SHARING
Install the dependencies:
iproute2, python3, python-stem, darkhttpd, tor, curl

Edit your /etc/tor/torrc to contain this:
  ControlPort 9051
  CookieAuthentication 1
  CookieAuthFile /var/lib/tor/control_auth_cookie
  CookieAuthFileGroupReadable 1
  DataDirectoryGroupReadable 1
  CacheDirectoryGroupReadable 1

Add your user to the tor group (debian-tor on ubuntu)

Proceed with 4. PRE-START.

3b. i2p-SHARING
Install the dependencies:
i2pd or i2p-java, iproute2, darkhttpd, curl

Configure a http tunnel (use the port number defined in your Goldkarpfen.config)
  cp start-services.sh my-start-services.sh
  cp stop-services.sh my-stop-services.sh

Edit my-start-service.sh and comment out the hidden service line:
  #python3 start-hidden-service.py $1 $2 70 #80 for http, 70 for gopher

Edit my-stop-service.sh and comment out the hidden service line:
  #python3 stop-hidden-service.py $1

Start your i2p-daemon.
Get your i2p hostname (f.e. i2pd: 127.0.0.1:7070/?page=i2p_tunnels ) and add it later from the running Goldkarpfen with [r][h]

Proceed with 4. PRE-START

4. PRE-START
Check the dependencies !!IMPORTANT!!
NOTE: On some systems (f.e. ubuntu) "which" won't output an error to stderr.
If check-dependencies.sh returns "ERROR", "tor-passive" or "PASSIVE" and no error message, then use ./check-dependencies-ubuntu.sh
  ./check-dependencies.sh  # run this until it returns "tor" or "i2p"

5. CREATE AN ACCOUNT
  ./new-account

Check the config:
  more ./Goldkarpfen.config

6. START
  bash ./Goldkarpfen.sh  # or
  mksh ./Goldkarpfen.sh  # or
  busybox sh ./Goldkarpfen.sh

Press [h] to get an overview.

NOTE: dash (and others) does not support "read -n 1" - Goldkarpfen will work, but you have to press ENTER a lot ;)

### OPTIONAL: GOPHER instead of HTTP (dependency: geomyidae or alike)
NOTE: Do something similar if you want to use a different http-server than darkhttpd.
  cp start-services.sh my-start-services.sh
  cp stop-services.sh my-stop-services.sh

Edit my-start-service.sh and comment out darkhttpd lines and add the gopher related lines:
  #darkhttpd archives/ --port $2 --daemon --log server.log --maxconn 10 --no-server-id --no-listing --pidfile ./tmp/darkhttpd.pid | sed 's/^/ \* /'
  geomyidae -b archives -p $2 -logfile server.log
  python3 start-hidden-service.py $1 $2 70 #80 for http, 70 for gopher

Edit my-stop-service.sh and comment out darkhttp lines and add:
  killall geomyidae #or come up with something more elaborated if you are running multiple instances

### BE SURE TO USE THE LATEST GOLDKARPFEN:
From a running Goldkarpfen (>= 2.1.42) you should be able to update via [r][A] [r][U]

#LICENSE:CC0
