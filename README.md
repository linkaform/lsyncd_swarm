
#Distributed Volume Storage for SWARM

The DVS for Swarm is a small and practical service (based on lsyncd using rsync) for distributed storage on SWARM.

## The Problem 
For regular volumes using swarm, or at least how I could configure it ond figure out. I coudn't find a way, except using a solution with Amazon or Google, to sincronize volume between Docker SWARM nodes. 


I did sevreal testing, but when the volume was shared on containers but across diferent nodes, the conteiners could not see the info of the node on their side. Many of the volume dirvers I saw were depricated or weren't open source.

So I decided to do a **Docker Swarm** service that can help us with.

## The Solution

The services run under **Alpine Linux** and is base on **lsyncd** . **Lsyncd** is a mirror soluction. As explained on https://axkibe.github.io/lsyncd/ lsync tha uses a filesystem event interface (inotify or fsevents) to watch for changes to local files and directories. Lsyncd collates these events for several seconds and then spawns one or more processes to synchronize the changes to a remote filesystem. The default synchronization method is rsync. Thus, Lsyncd is a light-weight live mirror solution. Lsyncd is comparatively easy to install and does not require new filesystems or block devices. Lysncd does not hamper local filesystem performance.

Axel Kittenberger (https://github.com/axkibe) comments that Lsyncd is useful for slowly changing sistem, not a database fast data system. So think of the **DVS for Swarm** as that. For keeping files sync, example profile pictures, shared files, any media, etc. It will sync like a master to master no mater the topology of your solution, it will automaicaly adjust to it as you number of nodes expand or contract. 

**DVS Swarm** is installed as a service directly on the **ymal** or **yml** use to diploy your stack.

### Requierments, whats needed???

You will need to set this prior requierments for it to work
- Create an **overlay network** under swarm called csi_network.

> docker network create -d overlay csi_lsyncd

- Set you secrets. Delcare them under the secret secction on you **docker-stack.yml**. If you don't decalte them, **DVS Swarm** will use the defautl, but this is not encurate to do on a production server. So set this secrets and they will be replace with the default ones.

>    secrets:
>      - id_rsa_lsyncd
>      - authorized_keys_lsyncd
>
>
- Declare on the Volume section and Attache the **all** the media volume you wish to sync and the docker socket.


>   volumes:
>      your_media:
>      db-volume:
>
>
>   volumes:
>      - /var/run/docker.sock:/var/run/docker.sock
>      - your_media:/srv/lsyncd_swarm/volumes/your_media
>

- Set ports. By default it uses the 7029, but you can change it to whatever you'll like, is just used for the ssh connection. 

>
> ports:
      - 7029
>

- Set environment variables. For now we only use 3. 

- **SYNC_VOLUMES**: Where you will list all the volumes to sync separated by a space.
- **MODE**: ALWAYS use swarm, I use other than that like compose for deguggin and testing.
- **HEARTBEAT**: Time expresed on seconds, that **DVS Swarm** will look for new peers.

- Always use ** mode: global **, or at least if you what to sync the node closter. But you can configurate it to use it only on sertain lables or node conditions.

>    deploy:
>     mode: global



## Example: 

services:
  lsyncd:
    image: linkaform/lsyncd_swarm:latest
    networks:
      - csi_lsyncd
    environment:
      SYNC_VOLUMES: infosync_media
      MODE: swarm
      HEARTBEAT: 25
    ports:
      - 7029
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - infosync_media:/srv/lsyncd_swarm/volumes/infosync_media
    command: /srv/lsyncd_swarm/scripts/make_configuration.sh
    secrets:
      - id_rsa_lsyncd
      - authorized_keys_lsyncd
    deploy:
      mode: global
      update_config:
        parallelism: 2
        delay: 5s
      restart_policy:
        condition: on-failure

  you_other_service_here:

## Disclaimer

Besides the usual disclaimer in the license, we want to specifically emphasize that neither the authors, nor any organization associated with the authors, can or will be held responsible for data-loss caused by possible malfunctions of **DVS Swarm**.