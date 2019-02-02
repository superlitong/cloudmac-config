ovs-vsctl del-controller br0
ovs-ofctl del-flows br0
CMD="ovs-ofctl add-flow br0"


$CMD priority=2,in_port=1,dl_src=00:00:00:01:00:00/00:00:ff:ff:00:00,actions=output:2
$CMD priority=2,in_port=1,dl_src=00:00:00:02:00:00/00:00:ff:ff:00:00,actions=output:3
$CMD priority=2,in_port=1,dl_src=00:00:00:04:00:00/00:00:ff:ff:00:00,actions=DROP
$CMD priority=2,in_port=1,dl_src=00:00:00:08:00:00/00:00:ff:ff:00:00,actions=DROP



$CMD priority=3,in_port=3,dl_src=00:22:FB:52:CE:AE,actions=output:1
$CMD priority=3,in_port=2,dl_src=00:22:FB:52:CE:AE,actions=DROP


$CMD priority=2,in_port=2,dl_dst=ff:ff:ff:ff:ff:ff,actions=drop
$CMD priority=2,in_port=3,dl_dst=ff:ff:ff:ff:ff:ff,actions=output:1

ovs-ofctl del-flows br0
$CMD priority=1,in_port=1,actions=output:3
$CMD priority=1,in_port=3,actions=output:1
$CMD priority=1,in_port=2,actions=DROP

 
