#!/bin/sh
echo 'starting...'                                                                                                                                                                                      
if [[ -e /srv/lsyncd_swarm/.csi/lsync.pid ]]; then
echo 'kill' 
    kill -15 $(cat /srv/lsyncd_swarm/.csi/lsync.pid )
    sleep 3
fi
echo 'starting'
touch /srv/lsyncd_swarm/.csi/lsync.pid                                                                                                                                                                                                                      
lsyncd -pidfile  /srv/lsyncd_swarm/.csi/lsync.pid /etc/lsyncd/lsyncd.conf
