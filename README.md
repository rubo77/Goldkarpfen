# Goldkarpfen
Goldkarpfen is a p2p-share-hosted daily-routine blogging system without any central authority. The unique selling point of Goldkarpfen is its calm way of publishing: nodes will only sync once a day. This is a more human aproach to communication and will reduce stress and improve the quality of content.

## INSTALLATION on Linux / BSD / Mac OSX / Windows-Subsystem for Linux?
For quick install instructions see MORE_ABOUT_GOLDKARPFEN.TXT

### GOLDKARPFEN FOR ANDROID (automated install)
**WARNING : will change `torrc`, `~/.bashrc` and `~/.profile` - also : ABSOLUTELY NO WARRANTY!**

1. install the app `termux` on your Android
2. `pkg upgrade ; pkg install tor curl && if ! pidof tor > /dev/null;then eval "tor --quiet &";fi;
VERSION=331_termux;REPO="https://gitlab.com/rubo77/Goldkarpfen/-";curl -f "$REPO/raw/main/gki.sh" > gki.sh && sh gki.sh "$REPO/archive/release_$VERSION" "Goldkarpfen-release_$VERSION.tar.gz"`

This is the "gitlab way" ; if possible : use the **Mobile2Mobile** installer instead

### GOLDKARPFEN FOR IOS (automated install)

1. install the app `iSH` on your iPhone
2. `pkg upgrade ; pkg install tor curl && if ! pidof tor > /dev/null;then eval "tor --quiet &";fi;
VERSION=331_termux;REPO="https://gitlab.com/rubo77/Goldkarpfen/-";curl -f "$REPO/raw/main/gki.sh" > gki.sh && sh gki.sh "$REPO/archive/release_$VERSION" "Goldkarpfen-release_$VERSION.tar.gz"`

### 1. Set EDITOR enviroment variable
Your `EDITOR` enviroment variable needs to be set similar to this (add this to `~/.bashrc` or `~/.mkshrc` or alike):

   export EDITOR="nano" # or "vi" :)

### 2. INSTALL THE BASIC DEPENDENCIES  
ag (the-silver-searcher), fzy (or fzf), libressl/openssl, xxd from vim/xxd-standalone, darkhttpd, curl, tor

*IMPORTANT:* test if the basic dependencies are met (must not return `ERROR`):  
`./check-dependencies.sh`

### 3. CREATE AN ACCOUNT

    ./new-account
    # note: KEY_ADDR
    # Check the config:
    more ./Goldkarpfen.config
    # note: SERVER_PORT

If you want an offline instance -> proceed with STEP 6.

### 4. Install the dependencies for download and hosting

    darkhttpd, curl

Test your settings:

    ./check-dependencies.sh
  
Should return: ... host get ok

### 5.Choose a method for hosting:
- 5A. ONION-CTRL
- 5B. ONION-STATIC
- 5C. I2P

### 5A. ONION-CTRL
Install the dependencies:

    python3, python-stem, tor

Edit your `/etc/tor/torrc` to contain this:

    ControlPort 9051
    CookieAuthentication 1
    CookieAuthFile /var/lib/tor/control_auth_cookie
    CookieAuthFileGroupReadable 1
    DataDirectoryGroupReadable 1
    CacheDirectoryGroupReadable 1

Add your user to the tor group (`debian-tor` on Ubuntu) (restart may be neccessary!)

Test your settings:

    ./check-dependencies.sh
    
Should return: tor-ctrl ...

### 5B. ONION-STATIC
Install the dependencies:

    tor

add this to your `/etc/torrc` (KEY_ADDR and SERVER_PORT from above)

    HiddenServiceDir /var/lib/tor/KEY_ADDR/
    HiddenServicePort 80 127.0.0.1:SERVER_PORT

Start tor (e.g. systemctl)

    sudo systemctl start tor

Test your settings:

    ./check-dependencies.sh
    
Should return: tor-static ...

### 5C. i2p-SHARING
Install the dependencies:  

    i2pd or i2p-java

configure a http tunnel (use SERVER_PORT defined in your Goldkarpfen.config)  
start your i2p-daemon (example i2pd)

    i2pd

Test your settings:

    ./check-dependencies.sh
    
Should return: ... i2p ...

### 6. START
NOTE: dash (and others) does not support "read -n 1" - Goldkarpfen will work, but you have to press [Return] a lot ;)
*NOTE: dash (and others) does not support "read -n 1" - Goldkarpfen will work, but you have to press [Return] a lot ;)*

    bash ./Goldkarpfen.sh  # or
    mksh ./Goldkarpfen.sh  # or
    busybox sh ./Goldkarpfen.sh

Press [h] to get an overview.

Get your service-url (if you have configured a ONION-hidden service or I2P-tunnel)

**ONION:**

    sudo cat /var/lib/tor/KEY_ADDR/hostname

**I2P (example i2pd):**
  
http://127.0.0.1:7070/?page=i2p_tunnels

and add your onion/i2p url with [r][h]

### 7. MORE INFO
- http://6f5bmqtipvz7wdurqx7ireer3j47wegaztivl5pnsiumk5jeurua.b32.i2p/share/FAQ.TXT
- http://6f5bmqtipvz7wdurqx7ireer3j47wegaztivl5pnsiumk5jeurua.b32.i2p/share/MORE_ABOUT_GOLDKARPFEN.TXT
- [DOC/FAQ.TXT]
- [DOC/MORE_ABOUT_GOLDKARPFEN.TXT]
- [DOC/help-en.dat]
- [DOC/ITP-DEFINITION]
- [DOC/address_migration.txt]

### Everyday usage
- press p to **create a new post**
- press a to update your own stream in ./archives. This will **publish** your stream for others to download
- press r and A check for **updates** and install with r and U 
- press r and w to check what's new in the streams you follow 
- press h for more features

#LICENSE:CC0
