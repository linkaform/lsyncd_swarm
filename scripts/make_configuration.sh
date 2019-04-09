#!/bin/sh
#script for configuration of the Lsync Swarm



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


# echo "Holding 45 secs while other nodes come to life"
# for i in `seq 1 45`;
#   do
#     sleep 1
#     echo $i ' sec ...'
#   done

MASTER_NODE_ID=$(docker node ls  |grep Leader | awk '{print $1}')
if [ -z "$MASTER_NODE_ID" ]
then
  MASTER_NODE=0
else
  MASTER_NODE=1
fi

set_node_conf(){
  container=$(cat /srv/lsyncd_swarm/.csi/container)
  CONTAINER_JSON=$(echo "{ 'Node': $container , 'IPAddress': $CURRENT_HOST" })
  echo $CONTAINER_JSON
}

get_peer_hosts(){
  NODES=$(docker node ls | sed -n '1!p' |awk '{print $1}')
  NODES_QTY=$(docker node ls | sed -n '1!p' |wc -l)
  rm /srv/lsyncd_swarm/.csi/peers_ips.txt
  for node in $NODES
  do
    IPADDRESS=$(docker node inspect $node | grep "Addr"|head -n 1 | awk '{print $2}')
    echo 'ip addres' $IPADDRESS
    echo $IPADDRESS >>  /srv/lsyncd_swarm/.csi/peers_ips.txt
  done
  sed -i 's/"//g' /srv/lsyncd_swarm/.csi/peers_ips.txt
  sed -i 's/,//g' /srv/lsyncd_swarm/.csi/peers_ips.txt
  sed -i "s/\/16//g" /srv/lsyncd_swarm/.csi/peers_ips.txt
  sed -i "s/\/24//g" /srv/lsyncd_swarm/.csi/peers_ips.txt
  md5sum /srv/lsyncd_swarm/.csi/peers_ips.txt | awk '{print $1}' > /srv/lsyncd_swarm/.csi/peers_ips.hash
}

seek_peers(){
    #searches for new friend to which they are going to send their information.
    CURRENT_HOST=$(ip route | grep eth0 | awk '{print $7}') 
    network=$(cat /srv/lsyncd_swarm/.csi/host_network)
    nmap -p 7029 $network -oG - | grep open | grep lsyncd | awk '{print $2}' > /srv/lsyncd_swarm/.csi/peers_ips.txt 
    # docker network inspect csi_lsyncd > /srv/lsyncd_swarm/.csi/network_peers.txt
    # grep '"IP":' /srv/lsyncd_swarm/.csi/network_peers.txt | awk '{print $2}' > /srv/lsyncd_swarm/.csi/peers_ips.txt
    sed -i 's/"//g' /srv/lsyncd_swarm/.csi/peers_ips.txt
    sed -i 's/,//g' /srv/lsyncd_swarm/.csi/peers_ips.txt
    sed -i "s/\/16//g" /srv/lsyncd_swarm/.csi/peers_ips.txt
    sed -i "s/\/24//g" /srv/lsyncd_swarm/.csi/peers_ips.txt
    md5sum /srv/lsyncd_swarm/.csi/peers_ips.txt | awk '{print $1}' > /srv/lsyncd_swarm/.csi/peers_ips.hash
}

search_new_peers(){
    nmap -p 7029 $network -oG - | grep open | grep lsyncd | awk '{print $2}' > /srv/lsyncd_swarm/.csi/new_peers_ips.txt 
    # docker network inspect csi_lsyncd > /srv/lsyncd_swarm/.csi/new_network_peers.txt
    # grep '"IP":' /srv/lsyncd_swarm/.csi/new_network_peers.txt | awk '{print $2}' > /srv/lsyncd_swarm/.csi/new_peers_ips.txt
    sed -i 's/"//g' /srv/lsyncd_swarm/.csi/new_peers_ips.txt
    sed -i 's/,//g' /srv/lsyncd_swarm/.csi/new_peers_ips.txt
    sed -i "s/\/16//g" /srv/lsyncd_swarm/.csi/new_peers_ips.txt
    sed -i "s/\/24//g" /srv/lsyncd_swarm/.csi/new_peers_ips.txt
    md5sum /srv/lsyncd_swarm/.csi/new_peers_ips.txt | awk '{print $1}' > /srv/lsyncd_swarm/.csi/new_peers_ips.hash
}


get_new_peers(){
  publish_peers="/srv/lsyncd_swarm/.csi/published_peers.txt"
  key='IPAddress'
  rm /srv/lsyncd_swarm/.csi/new_peers_ips.txt
  touch /srv/lsyncd_swarm/.csi/new_peers_ips.txt
  while IFS='-' read -r json
    do
      temp=$(echo $json | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $key)
      res=$(echo $temp | cut -d':' -f2 | sed 's/ //g')
      if [ -z $res ]; then
        true
      else
        echo $res >>/srv/lsyncd_swarm/.csi/new_peers_ips.txt
      fi
    done < "$publish_peers"
    md5sum /srv/lsyncd_swarm/.csi/new_peers_ips.txt | awk '{print $1}' > /srv/lsyncd_swarm/.csi/new_peers_ips.hash
}

set_peers_qty(){
  PEERS_QTY=$(cat /srv/lsyncd_swarm/.csi/peers_ips.txt | wc -l )
}


set_know_hosts(){
    #CURRENT_CONTAINER=$(cat /srv/lsyncd_swarm/.csi/container)
    set_node_conf
    CURRENT_HOST=$(ip route | grep eth0 | awk '{print $7}')
    echo "Current Host IP set as: " $CURRENT_HOST
    CURRENT_PEERS=$(cat /srv/lsyncd_swarm/.csi/peers_ips.txt)
    for remote_host in $CURRENT_PEERS
       do
        if grep -q $remote_host /srv/lsyncd_swarm/.ssh/known_hosts 
           then
             echo 'Skipping existing host:' $remote_host
            else
              echo 'Adding host: '$remote_host 
              echo [$remote_host]:7029 $( head -1 /srv/lsyncd_swarm/.ssh/known_hosts) >> /srv/lsyncd_swarm/.ssh/known_hosts
        fi
    done
}

publish_me(){
    #CURRENT_CONTAINER=$(cat /srv/lsyncd_swarm/.csi/container)
    set_node_conf
    echo 'set node conf after' 
    CURRENT_HOST=$(ip route | grep eth0 | awk '{print $7}')
    echo "Current Host IP set as: " $CURRENT_HOST
    CURRENT_PEERS=$(cat /srv/lsyncd_swarm/.csi/peers_ips.txt)
    echo "pubishing with this hosts CURRENT_PEERS:" $CURRENT_PEERS
    set_know_hosts
    publish_peers=$(cat /srv/lsyncd_swarm/.csi/published_peers.txt)
    for remote_host in $CURRENT_PEERS
       do
        echo 'next host --------------------- ' $remote_host
        REMOTE_COTNAINER=$(su lsyncd -c "ssh $remote_host -p 7029 'cat /srv/lsyncd_swarm/.csi/container'")
        #Coping remote peers to local peers
        REMOTE_CONF_PEERS=$(su lsyncd -c "ssh $remote_host -p 7029 'cat /srv/lsyncd_swarm/.csi/published_peers.txt'")
        echo $REMOTE_CONF_PEERS > /srv/lsyncd_swarm/.csi/remote_peers.txt
        sed -i 's/}/}\n/g' /srv/lsyncd_swarm/.csi/remote_peers.txt
        sed -i 's/ {/{/g' /srv/lsyncd_swarm/.csi/remote_peers.txt
        rr="/srv/lsyncd_swarm/.csi/remote_peers.txt"
        key='IPAddress'
        while IFS='-' read -r json
        do
          temp=$(echo $json | sed 's/\\\\\//\//g' ) #| sed 's/[{}]//g' ) #| awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $key)
            /srv/lsyncd_swarm/scripts/publish_me.sh $temp
        done < "$rr"
        echo 'Searching on IP:' $remote_host 'for container id...'
        echo 'The remote remote container id is:' $REMOTE_COTNAINER
        if [[ $REMOTE_COTNAINER != $CURRENT_HOST ]]; then
          su lsyncd -c "ssh $remote_host -p 7029 '/srv/lsyncd_swarm/scripts/publish_me.sh $CONTAINER_JSON'"
          publish_local_peers=$(cat /srv/lsyncd_swarm/.csi/published_peers.txt)
          key='IPAddress'
          echo 'con lista' $publish_local_peers
          su lsyncd -c "ssh $remote_host -p 7029 '/srv/lsyncd_swarm/scripts/publish_list.sh $publish_local_peers'"
          # cat .csi/published_peers.txt  | while read json
          #     do
          #       temp=$(echo $json | sed 's/\\\\\//\//g' )
          #       echo 'chismeando sobre...: ' $temp
          #       chismear $temp
          #     done 
        fi
    done
}

chismear(){
  json=$@
  echo 'json' $json
  echo 'd'
  REMOTE_COTNAINER=$(su lsyncd -c "ssh $remote_host -p 7029 '/srv/lsyncd_swarm/scripts/publish_list.sh $json'")
  echo 'end'
}

get_hosts(){
  CURRENT_PEERS=$(cat /srv/lsyncd_swarm/.csi/peers_ips.txt)
  CURRENT_HOST=$(ip route | grep eth0 | awk '{print $7}')
  for this_host in $CURRENT_PEERS
      do
        if [ $this_host != $CURRENT_HOST ]; then
          echo 'doing host: ' $this_host
          cat /srv/lsyncd_swarm/conf/sync_template.txt >>/etc/lsyncd/lsyncd.conf
          sed -i "s/_IPv4ADDRESS/${this_host}/g" /etc/lsyncd/lsyncd.conf
        fi
      done
}

set_settings(){
    cp /srv/lsyncd_swarm/conf/settings_template.txt /etc/lsyncd/lsyncd.conf
    echo \ >> /etc/lsyncd/lsyncd.conf
}

volume_config(){
    for this_volume in $SYNC_VOLUMES
    do
        echo "++++++++ vol config +++++++++ = " $this_volume
        get_hosts
        sed -i "s/_VOLUME_NAME/${this_volume}/g" /etc/lsyncd/lsyncd.conf
        chown lsyncd:lsyncd /srv/lsyncd_swarm/volumes/$this_volume
    done
}


start_lsync(){
  touch /srv/lsyncd_swarm/.csi/lsync.pid
  pid=$(cat /srv/lsyncd_swarm/.csi/lsync.pid)
  if [[ $pid > 0 ]]; then
    kill kill $(cat /srv/lsyncd_swarm/.csi/lsync.pid )
  fi
  lsyncd -pidfile  /srv/lsyncd_swarm/.csi/lsync.pid /etc/lsyncd/lsyncd.conf  
}

if [ $MASTER_NODE == 1 ]; then
  get_peer_hosts
else
  seek_peers
fi
set_peers_qty
set_know_hosts
publish_me
echo "Holding 40 secs while other nodes come to life"
for i in `seq 1 45`;
  do
    sleep 1
    echo $i ' sec ...'
  done

while [ -z $(cat /srv/lsyncd_swarm/.csi/new_peers_ips.txt) ]
  do
    echo 'Configuring new published peers'
    get_new_peers
    sleep 2
    echo '...'
  done

cp /srv/lsyncd_swarm/.csi/new_peers_ips.txt /srv/lsyncd_swarm/.csi/peers_ips.txt 
md5sum /srv/lsyncd_swarm/.csi/peers_ips.txt | awk '{print $1}' > /srv/lsyncd_swarm/.csi/peers_ips.hash

set_settings
volume_config
#su lsyncd -c '/srv/lsyncd_swarm/scripts/start_lsync.sh'

cat /etc/lsyncd/lsyncd.conf 



#TODO, CUANDO PRENDA VAMOS A ESCRIBIR EN QUE CONTAINER ESTAMOS, DE ESTA MANERA 
#HACEMOS UN SSH Y ESE ES DE DONDE TOMA EL HOST

if [ -z "$HEARTBEAT" ]
then
      echo "HeartBeat set to pump every " $HEARTBEAT "seconds..."
else
      HEARTBEAT=60
      echo "No HeartBeat config found, settig defautl to pump every " $HEARTBEAT "seconds..."
fi

while :
do
  RESTART=0
  echo "Searching for new peers."
  #CONF_PEERS_QTY=$(($(docker network inspect csi_lsyncd |grep EndpointID | wc -l ) -1 ))
  CONF_PEERS_QTY=$(grep host /etc/lsyncd/lsyncd.conf | wc -l)
  if [[ $CONF_PEERS_QTY != $PEERS_QTY ]]; then
    echo "Renewing conf due to peers not configure"
    echo "Config peers $CONF_PEERS_QTY no equal to $PEERS_QTY used peers"
    RESTART=1
  elif [[ $(cat /srv/lsyncd_swarm/.csi/peers_ips.hash) !=  $(cat /srv/lsyncd_swarm/.csi/new_peers_ips.hash) ]]; then
    echo "Renewing peers new peers found..."
    echo "Old known peers Hash:" $(cat /srv/lsyncd_swarm/.csi/peers_ips.hash) 
    echo "New found peers Hash:" $(cat /srv/lsyncd_swarm/.csi/new_peers_ips.hash) 
    echo "Old peers" $(cat /srv/lsyncd_swarm/.csi/peers_ips.txt)
    echo "New peers" $(cat /srv/lsyncd_swarm/.csi/new_peers_ips.txt)
    RESTART=1
  fi
  if [[ $RESTART == 1 ]]; then
    echo 'renew peers'
    cp /srv/lsyncd_swarm/.csi/new_peers_ips.txt /srv/lsyncd_swarm/.csi/peers_ips.txt 
    md5sum /srv/lsyncd_swarm/.csi/peers_ips.txt | awk '{print $1}' > /srv/lsyncd_swarm/.csi/peers_ips.hash
    get_peers
    set_peers_qty
    set_settings
    volume_config
    publish_me
    get_new_peers
    #su lsyncd -c '/srv/lsyncd_swarm/scripts/start_lsync.sh'
  else
    search_new_peers
  fi
  sleep $HEARTBEAT
done

# if [ "$a" -ne "$b" ]
#   then
#   echo "$a is not equal to $b"
#   echo "(arithmetic comparison)"
# fi
