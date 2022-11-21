# Goldkarpfen
Goldkarpfen is a p2p-share-hosted daily-routine blogging system without any central authority. The unique selling point of Goldkarpfen is its calm way of publishing: nodes will only sync once a day. This is a more human aproach to communication and will reduce stress and improve the quality of content.

## INSTALLATION AND FIRST START

For quick install instructions see MORE_ABOUT_GOLDKARPFEN.TXT

### 1. Set EDITOR enviroment variable
Your `EDITOR` enviroment variable needs to be set similar to this (add this to `~/.bashrc` or `~/.mkshrc` or alike):

   export EDITOR="nano"

### 2. Install the basic dependencies:  
ag (the-silver-searcher), fzy (or fzf), libressl/openssl, xxd from vim/xxd-standalone

Choose a method for hosting: 3a. ONION-SHARING _or_ 3b. i2p-SHARING

### 3a. ONION-SHARING  
Install the dependencies:  
iproute2, python3, python-stem, darkhttpd, tor, curl

Edit your /etc/tor/torrc to contain this:

    ControlPort 9051
    CookieAuthentication 1
    CookieAuthFile /var/lib/tor/control_auth_cookie
    CookieAuthFileGroupReadable 1
    DataDirectoryGroupReadable 1
    CacheDirectoryGroupReadable 1

Add your user to the tor group (`debian-tor` on Ubuntu)

Proceed with 4. PRE-START.

### 3b. i2p-SHARING
Install the dependencies:  
i2pd or i2p-java, iproute2, darkhttpd, curl

Copy the service files:

    cp start-services.sh my-start-services.sh
    cp stop-services.sh my-stop-services.sh

Edit `my-start-service.sh` and comment out the hidden service line:

    #python3 start-hidden-service.py $1 $2 70 #80 for http, 70 for gopher

Edit my-stop-service.sh and comment out the hidden service line:
  #python3 stop-hidden-service.py $1

###### AFTER STEP 5
configure a http tunnel (use the port number defined in your Goldkarpfen.config)  
start your i2p-daemon
###### AFTER STEP 6
get your i2p hostname (i.e. i2pd: 127.0.0.1:7070/?page=i2p_tunnels ) and add with [r][h]

Proceed with 4. PRE-START

### 4. PRE-START
Check the dependencies !!IMPORTANT!!  
NOTE: On some systems (i.e. ubuntu) "which" won't output an error to stderr.  
If `check-dependencies.sh` returns "ERROR", "tor-passive" or "PASSIVE" and no error message, then use `./check-dependencies-ubuntu.sh`  

    ./check-dependencies.sh  # run this until it returns "tor" or "i2p"

### 5. CREATE AN ACCOUNT
    ./new-account

Check the config:

    more ./Goldkarpfen.config

### 6. START
    bash ./Goldkarpfen.sh  # or
    mksh ./Goldkarpfen.sh  # or
    busybox sh ./Goldkarpfen.sh

Press [h] to get an overview.

*NOTE: dash (and others) does not support "read -n 1" - Goldkarpfen will work, but you have to press [Return] a lot ;)*

### Everyday usage
- press p to **create a new post**
- press a to update your own stream in ./archives. This will **publish** your stream for others to download
- press r and A check for **updates** and install with r and U 
- press r and w to check what's new in the streams you follow 
- press h for more features

### OPTIONAL: GOPHER instead of HTTP
(dependency: geomyidae or alike)  
NOTE: Do something similar if you want to use a different http-server than darkhttpd.

    cp start-services.sh my-start-services.sh
    cp stop-services.sh my-stop-services.sh

Edit `my-start-service.sh` and comment out darkhttpd lines and add the gopher related lines:

    #darkhttpd archives/ --port $2 --daemon --log server.log --maxconn 10 --no-server-id --no-listing --pidfile ./tmp/darkhttpd.pid | sed 's/^/ \* /'
    geomyidae -b archives -p $2 -logfile server.log
    python3 start-hidden-service.py $1 $2 70 #80 for http, 70 for gopher

Edit `my-stop-service.sh` and comment out darkhttp lines and add:

    killall geomyidae #or come up with something more elaborated if you are running multiple instances

### BE SURE TO USE THE LATEST GOLDKARPFEN:
From a running Goldkarpfen (>= 2.1.42) you should be able to update via [r][A] [r][U]

### Further Information
- help-en.dat
- MORE_ABOUT_GOLDKARPFEN.TXT
- FAQ.TXT
- ITP-DEFINITION
- address_migration.txt

#LICENSE:CC0
