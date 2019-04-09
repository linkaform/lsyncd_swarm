FROM docker

RUN apk update && \
   apk add  --no-cache \
   lsyncd \
   openssh-server \
   openssh-client \
   shadow \
   nmap

RUN ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa

RUN usermod -u 1000 xfs
RUN groupmod -g 1000 xfs

#RUN addgroup -S lsyncd --gid 1000 && adduser -D -S -h /srv/lsyncd_swarm -u 1000 -g 1000 -s /bin/sh -G lsyncd lsyncd 
RUN addgroup -S lsyncd  --gid 33 && adduser -D -S -h /srv/lsyncd_swarm -u 33 -g 33 -s /bin/sh -G lsyncd lsyncd 

RUN sed -i "s/lsyncd:!/lsyncd:*/g" /etc/shadow
#RUN usermod -aG docker lsyncd

RUN mkdir /var/log/lsyncd
RUN chown lsyncd:lsyncd -R /var/log/lsyncd

COPY --chown=lsyncd:lsyncd ./scripts /srv/lsyncd_swarm/scripts
COPY --chown=lsyncd:lsyncd ./conf /srv/lsyncd_swarm/conf

RUN  cp /srv/lsyncd_swarm/conf/sshd_config /etc/ssh/sshd_config
RUN  /usr/sbin/sshd

USER lsyncd
RUN ssh-keygen -f /srv/lsyncd_swarm/.ssh/id_rsa -N '' -t rsa
RUN cp /srv/lsyncd_swarm/.ssh/id_rsa.pub /srv/lsyncd_swarm/.ssh/authorized_keys
RUN chmod 600 /srv/lsyncd_swarm/.ssh/authorized_keys
RUN echo ssh-rsa  $(cat /etc/ssh/ssh_host_rsa_key.pub | awk '{print $2}') > /srv/lsyncd_swarm/.ssh/known_hosts
RUN chmod 644 /srv/lsyncd_swarm/.ssh/known_hosts



RUN mkdir /srv/lsyncd_swarm/.csi
RUN mkdir /srv/lsyncd_swarm/volumes
WORKDIR /srv/lsyncd_swarm/

USER root
CMD ["/srv/lsyncd_swarm/scripts/make_configuration.sh"]
