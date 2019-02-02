#!/bin/sh
SWITCH_IP=10.0.0.3
CHANNEL=4
#MAC=02:00:00:00:00:00
NUMRADIOS=1 
#PHY=`iw list |grep Wiphy | cut -d" " -f2 |tail -n1`
PHY=phy0

getnodeid() {
  NODEID=`ifconfig br-lan | grep inet | sed s/:/\ / | awk ' { print $3; } ' |cut -d"." -f4`
  return $NODEID
}



stop_ovs() {
    echo "stop_ovs"
        ovs-vsctl del-br br0
        #/etc/init.d/openvswitch stop
}

start_ovs() {
    echo "start_ovs"
    getnodeid
    ID=$?
    echo "$ID"
    /etc/init.d/openvswitch start
    ovs-vsctl add-br br0
    ovs-vsctl -- add-port br0 gre0 -- set Interface gre0 type=gre "options:remote_ip=$SWITCH_IP" "options:key=$ID"
    ifconfig br0 up
    ovs-ofctl del-flows br0
    ovs-ofctl add-flow br0 in_port=1,actions:output=2
    ovs-ofctl add-flow br0 in_port=2,dl_type=0x1337,priority=100,actions:output=1
    ovs-ofctl add-flow br0 in_port=2,dl_type=0x3713,priority=100,actions:output=1
    ovs-ofctl add-flow br0 in_port=2,priority=1,actions:output=DROP     
}

start_wlan() {
    echo "start_wlan"
    getnodeid
    ID=$?
    NUM=16
    pkill hostapd &>/dev/null
    MAC=`/tmp/usr/bin/python -c "print ':'.join([(('0a0b%04xccdd' % 0)[i:i+2]) for i in range(0, 12, 2)])"`
    echo "$MAC"
    iw phy $PHY interface add mon0 type monitor
    #ip link set dev mon0 address $MAC
    ifconfig mon0 hw ether $MAC
    ifconfig mon0 up

    ovs-vsctl -- add-port br0 mon0
    iw dev wlan0 del

    for NUM in `seq 0 $(($NUMRADIOS-1))`; do
      MAC=`/tmp/usr/bin/python -c "print ':'.join([(('0a0b%04xccdd' % 0)[i:i+2]) for i in range(0, 12, 2)])"`
      MAC=`/tmp/usr/bin/python -c "print ':'.join([(('0a0b%04xccdd' % pow(2, min("$NUM",16)))[i:i+2]) for i in range(0, 12, 2)])"`
      iw phy $PHY interface add wlan$NUM type station
      #ip link set dev wlan$NUM address $MAC
      ifconfig wlan$NUM hw ether $MAC
    done
    #iwconfig mon0 channel $CHANNEL
    iw dev mon0 set channel $CHANNEL
    ifconfig br0 mtu 1600
    #ifconfig wlan8 up
    #ifconfig wlan8 down
    sleep 2
    #iwconfig mon0 channel $CHANNEL
    iw dev mon0 set channel $CHANNEL
    #ifconfig wlan8 up


}


reload_driver() {
    echo "Reload WLAN driver"
    for MOD in ath5k ath9k ath9k_common ath9k_hw ath mac80211 cfg80211 compat; do
      rmmod $MOD &> /dev/null
      sleep 1
    done
    sleep 1
    insmod compat
    insmod cfg80211 ieee80211_regdom=GB
    insmod mac80211
    insmod ath
    insmod ath9k_hw
    insmod ath9k_common 
    insmod ath9k nohwcrypt=1
    sleep 1

}

start_controller() {
   echo "start_controller"
   ../cloudmacd/cloudmacd.py --start
}

stop_controller() {
   echo "stop_controller"
   ../cloudmacd/cloudmacd.py --stop
}


stop_controller
stop_ovs
reload_driver
start_ovs
start_wlan
start_controller

