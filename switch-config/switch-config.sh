#!/bin/bash
CONTROLLER=127.0.0.1:6633
VAP_IP=10.0.0.1
VAP_KEY=10
WTP_PREFIX=10.0.0
WTPS="10"
GOOD=5
BAD="2 3 4"




clear_config() {
  ovs-vsctl del-br br0
}


config_ovs() {
  echo "Configuring and starting ovs"
  ovs-vsctl add-br br0
  ovs-vsctl set-controller br0 tcp:$CONTROLLER
  ip link add type veth
  #ifconfig veth0 up
  #pkill capsulator &>/dev/null
  #../capsulator/capsulator  -t eth0 -f $VAP_IP -b veth0#1 &
  #ovs-vsctl -- add-port br0 veth0
  ovs-vsctl -- add-port br0 gre0-100 -- set Interface gre0-100 type=gre "options:remote_ip=$VAP_IP" "options:key=$VAP_KEY"
  for WTP in $WTPS; do
   
    ovs-vsctl -- add-port br0 gre0-$WTP -- set Interface gre0-$WTP type=gre "options:remote_ip=${WTP_PREFIX}.$WTP" "options:key=$WTP"
  done

}

add_rules() {
WTPS="10"
GOOD=3
BAD="2"
ovs-vsctl del-controller br0
  ovs-ofctl del-flows br0

 # ovs-ofctl add-flow br0 in_port=3,dl_dst=ff:ff:ff:ff:00:60,priority=999,actions=DROP
 # ovs-ofctl add-flow br0 in_port=3,dl_src=00:60:00:00:00:00/ff:ff:00:00:00:00,priority=999,actions=DROP
  ovs-ofctl add-flow br0 in_port=$GOOD,actions:output=1
  ovs-ofctl add-flow br0 in_port=1,actions:output=$GOOD
  for B in $BAD; do
    ovs-ofctl add-flow br0 in_port=$B,actions:output=1
  done
  
}

if (( EUID != 0 )); then
    echo "You must be root to do this." 1>&2
    exit 1
fi

clear_config
config_ovs
#add_rules
