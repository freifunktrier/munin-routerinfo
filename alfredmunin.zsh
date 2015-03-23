#!/bin/zsh

: <<EOL
The MIT License (MIT)

Copyright © 2015-03-23 Kyra 'nonchip' Zimmer <me@nonchip.de>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

EOL

ALFRED_JSON="alfred-json"

MAC="$(basename "$0" | cut -d_ -f 2)"
MODE="$(basename "$0" | cut -d_ -f 3)"

HOSTNAME="$($ALFRED_JSON -z -r 158 | jq ".[\"$MAC\"].hostname" -)"

fetch_json(){
	$ALFRED_JSON -z -r 159
}

extract_json(){
  jq ".[\"$1\"]" -
}

format_memory(){
  jq ".buffers,.total,.cached,.free" - | tr "\n" " " | read buffers total cached free
  used=$(($total-$free-$buffers-$cached))
cat <<EOM
buffers.value $buffers
total.value $total
cached.value $cached
free.value $free
used.value $used
EOM
}

format_loadavg(){
  echo -n "load.value "
  cat
}

format_uptime(){
  echo -n "uptime.value "
  cat
}

format_processes(){
  jq ".total,.running" - | tr "\n" " " | read total running
cat <<EOM
total.value $total
running.value $running
EOM
}

format_traffic(){
  jq ".tx.bytes,.mgmt_tx.bytes,.rx.bytes,.mgmt_rx.bytes,.forward.bytes" - | tr "\n" " " | read tx mgmt_tx rx mgmt_rx forward
cat <<EOM
tx.value $tx
mgmt_tx.value $mgmt_tx
rx.value $rx
mgmt_rx.value $mgmt_rx
forward.value $forward
EOM
}

format_clients(){
  jq ".total,.wifi" - | tr "\n" " " | read total wifi
cat <<EOM
total.value $total
wifi.value $wifi
EOM
}

config_memory(){ cat <<EOM
graph_title Memory for $HOSTNAME
graph_category system
graph_args --base 1000 -l 0
graph_vlabel Bytes
graph_order used buffers cached free
used.label used
buffers.label buffers
cached.label cached
free.label free
used.draw AREA
buffers.draw STACK
cached.draw STACK
free.draw STACK
EOM
  for i in used buffers cached free
    do echo "$i.type GAUGE"
    echo "$i.min 0"
  done
}

config_loadavg(){ cat <<EOM
graph_title Load avg for $HOSTNAME
graph_args --base 1000 -l 0
graph_vlabel load
graph_scale no
graph_category system
load.label loadavg
EOM
}

config_uptime(){ cat <<EOM
graph_title Uptime for $HOSTNAME
graph_args --base 1000 -l 0
graph_vlabel seconds
graph_category system
uptime.label uptime
EOM
}

config_processes(){ cat <<EOM
graph_title Processes for $HOSTNAME
graph_args --base 1000 -l 0
graph_vlabel number
graph_category system
running.label running
total.label total
EOM
}

config_clients(){ cat <<EOM
graph_title Clients for $HOSTNAME
graph_args --base 1000 -l 0
graph_vlabel number
graph_category system
wifi.label wifi
total.label total
EOM
}

config_traffic(){ cat <<EOM
graph_title Traffic for $HOSTNAME
graph_args --base 1000
graph_vlabel bits in (-) / out (+) per \${graph_period}
rx.label rx bps
rx.type DERIVE
rx.graph no
rx.cdef rx,8,*
tx.label client bps
tx.type DERIVE
tx.negative rx
tx.cdef tx,8,*
mgmt_rx.label mrx bps
mgmt_rx.type DERIVE
mgmt_rx.graph no
mgmt_rx.cdef mgmt_rx,8,*
mgmt_tx.label mgmt bps
mgmt_tx.type DERIVE
mgmt_tx.negative mgmt_rx
mgmt_tx.cdef mgmt_tx,8,*
forward.label forward bps
forward.type DERIVE
forward.cdef forward,8,*
EOM
}

case $1 in
   config) # --upper-limit $memtotal
        echo "host_name $(echo $MAC | tr -d :)"
        config_$MODE $MAC
        exit 0;;
   symlink_install)
        for i in clients loadavg memory processes traffic uptime
          do ln -s $(readlink -f "$0") /etc/munin/plugins/alfred_$2_$i
        done
        exit 0;;
esac

fetch_json | extract_json $MAC | extract_json $MODE | format_$MODE
