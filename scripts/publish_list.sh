#!/bin/sh

json="$*"

echo 'paramas' $json
echo $json >/srv/lsyncd_swarm/.csi/recibed_peers.txt
sed -i 's/}/}\n/g' /srv/lsyncd_swarm/.csi/recibed_peers.txt
sed -i 's/ {/{/g' /srv/lsyncd_swarm/.csi/recibed_peers.txt

echo "current recibed_peers:" $(cat /srv/lsyncd_swarm/.csi/recibed_peers.txt)
rr="/srv/lsyncd_swarm/.csi/recibed_peers.txt"
while IFS='-' read -r json
do
  temp=$(echo $json | sed 's/\\\\\//\//g' ) #| sed 's/[{}]//g' ) #| awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $key)
  echo 'test tesmp' $temp
  if [ -z "$temp" ]; then
    echo 'vacio'
  else
    echo 'aqui va con ' $temp
    sh /srv/lsyncd_swarm/scripts/publish_me.sh $temp
  fi
done < "$rr"
