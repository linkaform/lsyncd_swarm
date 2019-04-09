#!/bin/sh
#This script should run every hour or so, to checkup up the config
#peers are still alive.




echo "Reciving information from server " "$@"

PARAMS="$@"
get_config_peers(){
       CONF_PEERS=$(grep IPADDRESS /etc/lsyncd/lsyncd.conf )
       for $remote_host in $CONF_PEERS
        do
            echo "Checking up the remote server: " $remote_host
            EXISTS=$(su lsyncd -c "ssh $remote_host -p 7029 'cat /srv/lsyncd_swarm/.csi/conf_as'")
            IF [ $EXISTS == 'master' |} $EXISTS == 'slave']; then
               echo "Server " $remote_host "found working ok ..."
            else
               sed -i.bak '/$remote_host/d' /srv/lkf_csi/.csi/peers_ips.txt 
        done
        EXISTING_PEERS=$(cat /srv/lkf_csi/.csi/peers_ips.txt)
        sh -c '/srv/lsyncd_swarm/script/renew_conf.sh $EXISTING_PEERS' 

#   echo #2 
 }


# Set_me_up(){

# }

# up_date_me(){

# }

look_up_for_me