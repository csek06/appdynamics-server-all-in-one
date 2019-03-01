FROM phusion/baseimage:0.10.2

MAINTAINER csek06

VOLUME ["/config"]

EXPOSE 9191 8090 8181 9080 9081 7001 7002

RUN export DEBCONF_NONINTERACTIVE_SEEN=true DEBIAN_FRONTEND=noninteractive && \
apt-get update && \
apt-get install -y \
libaio1 numactl tzdata wget && \
usermod -u 99 nobody && \
usermod -g 100 nobody && \
mkdir -p /etc/my_init.d

COPY firstrun.sh /etc/my_init.d/firstrun.sh
COPY response.varfile /root/response.varfile
COPY response-eum.varfile /root/response-eum.varfile

RUN chmod +x /etc/my_init.d/firstrun.sh
