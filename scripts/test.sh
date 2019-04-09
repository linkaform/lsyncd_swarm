#!/bin/sh
#script for configuration of the DVS Swarm
echo "arrancando dvs swarm================"
echo "============================ ...."


set_sshd(){
  #todo set up can login only form peers 
  sed -i "s/lsyncd:!/lsyncd:*/g" /etc/shadow
  cp /srv/lsyncd_swarm/conf/sshd_config /etc/ssh/sshd_config
  /usr/sbin/sshd
} 

set_sshd
echo $(docker ps | grep lsyncd_swarm | awk '{print $1}') > /srv/lsyncd_swarm/.csi/container
CURRENT_HOST=$(ip route | grep eth0 | awk '{print $7}') 
echo $CURRENT_HOST | sed 's/\./ /g'| awk '{print $1"."$2"."$3".*"}' >/srv/lsyncd_swarm/.csi/host_network

echo "3333333 ...."
sleep 999999999999999999

/bin/ash