#!/bin/ash
#Remake config and restart the server


cp /srv/lsyncd_swarm/conf/settings_template.txt /etc/lsyncd/lsyncd.conf
echo \ >> /etc/lsyncd/lsyncd.conf
for this_host in $CURRENT_PEERS
    do
      if [ $this_host != $CURRENT_HOST ]; then
        echo 'doing host: ' $this_host
        cat /srv/lsyncd_swarm/conf/sync_template.txt >>/etc/lsyncd/lsyncd.conf
        sed -i "s/_IPv4ADDRESS/${this_host}/g" /etc/lsyncd/lsyncd.conf
      fi
    done

su lsyncd -c '/srv/lsyncd_swarm/scripts/start_lsync.sh'
