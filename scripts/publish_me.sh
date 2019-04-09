#!/bin/sh
function jsonval {
    temp=$(echo $json | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $key)
    echo $temp | cut -d':' -f2 | sed 's/ //g'
}

json="$*"

echo 'paramas' $json

echo "current published_peers:" $(cat /srv/lsyncd_swarm/.csi/published_peers.txt)

get_ip_configure(){
    key='IPAddress'
    value=`jsonval`
    #echo "value for $key:" $value 
    CONF_PEERS_QTY=$(grep "\<$value\>" /srv/lsyncd_swarm/.csi/published_peers.txt | wc -l)
    #echo "Cantaida" $CONF_PEERS_QTY
    if [ $CONF_PEERS_QTY == "0" ]; then
        echo 0 
    else
        echo 1
    fi
}

get_node_configure(){
    key='Node'
    value=`jsonval`
    #echo "value for $key:" $node_value 
    CONF_PEERS_QTY=$(grep "\<$value\>" /srv/lsyncd_swarm/.csi/published_peers.txt | wc -l)
    #echo "Cantaida" $CONF_PEERS_QTY
    if [ $CONF_PEERS_QTY == "0" ]; then
        echo 0
    else
        echo 1    
    fi
}

node_preset=`get_node_configure`
ip_preset=`get_ip_configure`

echo 'node_preset' $node_preset
echo 'ip_preset' $ip_preset
get_node_configure(){
    if [ $node_preset == '1' ]; then 
        if [ $ip_preset == '1' ]; then 
          echo 0
        else
          #TODO there is the remote posiblity that the ip is confgiure but on different
          #Node, due the fact that the node id is unique this posilbity is far remote (I hope)
          key='Node'
          node_value=`jsonval`
          sed -i.bak "/$node_value/d" /srv/lsyncd_swarm/.csi/published_peers.txt
          echo 1
        fi
    else
        if [ $ip_preset == '1' ]; then 
          key='IPAddress'
          ip_value=`jsonval`
          sed -i.bak "/$ip_value/d" /srv/lsyncd_swarm/.csi/published_peers.txt
          echo 1
        else
          echo 1
        fi
    fi
}

renew=`get_node_configure`     
echo 'renew confgi' $renew
if [ $renew == "1" ]; then
    echo 'renewing config with values' $json
    if [ -z "$json" ]; then
      echo 'vacio'
    else
      echo $json >>/srv/lsyncd_swarm/.csi/published_peers.txt
    fi
fi
sed -i '/^$/d' /srv/lsyncd_swarm/.csi/published_peers.txt
echo "SALIDA:" $(cat /srv/lsyncd_swarm/.csi/published_peers.txt)

# CONF_PEERS_QTY=$(grep $value /srv/lsyncd_swarm/.csi/published_peers.txt | wc -l)
# echo "CAntaida" $CONF_PEERS_QTY
