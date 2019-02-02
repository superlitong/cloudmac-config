#/bin/bash
NUMRADIOS=1
SWITCH_IP=10.0.0.3
SWITCH_KEY=10
CHANNEL=4
SSID="CLOUDMAC"


clear_all() {
  echo "Clearing syslog"
  dmesg -c > /dev/null
}

reload_driver() {
  echo "Reloading kernel modules"
  killall hostapd
  modprobe mac80211_hwsim
  rmmod mac80211_hwsim
  rmmod mac80211
  rmmod cfg80211
  #ovs-vsctl del-port br0 cloud0
  modprobe cfg80211 ieee80211_regdom=GB
  
  modprobe mac80211
  modprobe mac80211_hwsim radios=$NUMRADIOS
  echo "Starting hwsim0 Interface"
  ifconfig hwsim0 up
}


create_hostapdconf() {
    echo "Creaing configuration files"
for NUM in `seq 0 $(($NUMRADIOS-1))`; do
		BSSID=`python -c "print ':'.join([(('0a0b%04xccdd' % pow(2, min("$NUM",16)))[i:i+2]) for i in range(0, 12, 2)])"`
		HIER="
driver=nl80211
hw_mode=g
channel="$CHANNEL"
bssid="$BSSID"
interface=wlan"$NUM"
ssid="$SSID$NUM"
#supported_rates=10 20 55 110 60 90 120 180 240 360 480 540
#basic_rates=60 120 240
supported_rates=60
basic_rates=60
beacon_int=100
dtim_period=1
#max_num_sta=1
#wpa=1
#wpa_passphrase=passlan1234
#wpa_key_mgmt=WPA-PSK
"

  echo "$HIER" > /tmp/hostapd-wlan$NUM.conf
done
}

start_hostapd() {
  echo "Starting hostapd"
  for NUM in `seq 0 $(($NUMRADIOS-1))`; do
     echo "Starting hostapd for interface wlan$NUM"
     hostapd -B /tmp/hostapd-wlan$NUM.conf 
  done
}


stop_ovs() {
  ovs-vsctl del-br br0
  /etc/init.d/openvswitch-switch stop

}

start_ovs() {
  echo "Configuring OpenVSwitch"
  /etc/init.d/openvswitch-switch start
  
  for NUM in `seq 0 $(($NUMRADIOS-1))`; do
  #  ifconfig wlan$NUM 192.168.$NUM.1
        ifconfig wlan$NUM up
    ifconfig wlan$NUM mtu 1200
  done
  ifconfig cloud0 up
  ovs-vsctl add-br br0
  ovs-vsctl del-port br0 gre0
  ovs-vsctl add-port br0 gre0 -- set Interface gre0 type=gre options:remote_ip=$SWITCH_IP options:key=$SWITCH_KEY
  ovs-vsctl del-port br0 cloud0
  ovs-vsctl add-port br0 cloud0
  ifconfig br0 mtu 1600
 # pkill capsulator &>/dev/null
 # ../capsulator/capsulator  -t eth0 -f $SWITCH_IP -b cloud0#1 &
}

start_gw() {
  ovs-vsctl add-br br1
  
  for NUM in `seq 0 $(($NUMRADIOS-1))`; do
    ovs-vsctl add-port br1 wlan$NUM
  done
   ovs-vsctl add-port br1 eth0
   /etc/init.d/udhcpd restart
  ifconfig br1 10.0.0.1
}

### Main starts here ####

 
if (( EUID != 0 )); then
    echo "You must be root to do this." 1>&2
    exit 1
fi


clear_all
stop_ovs
reload_driver
create_hostapdconf
start_hostapd
start_ovs	
start_gw
