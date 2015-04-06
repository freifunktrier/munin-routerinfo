# munin-routerinfo
is a zsh-skript to give munin acces to information alfred collects about routers

## requirements
* zsh
* alfred-json
* jq

## usage
    git clone https://github.com/freifunktrier/munin-routerinfo.git
    cd munin-routerinfo
if alfred-json is not in path - adjust the ALFRED_JSON="alfred-json" - Line



for each router run

    ./alfredmunin.zsh symlink_install <routerid>

this automatically adds a

    [localhost.localdomain;<routerid without colons>]
        address 127.0.0.1

block to your /etc/munin/munin.conf

For example for 00000-Ranlvor-dev I had to use

    ./alfredmunin.zsh symlink_install c4:6e:1f:a2:33:cc
