FROM phusion/baseimage:0.11

LABEL maintainer="csek06"

VOLUME ["/opt/appdynamics"]

RUN export DEBCONF_NONINTERACTIVE_SEEN=true DEBIAN_FRONTEND=noninteractive && \
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xB1998361219BD9C9 && \
apt-add-repository 'deb http://repos.azulsystems.com/ubuntu stable main' && \
apt-get update && \
apt-get install -y \
curl libaio1 libncurses5 numactl iproute2 iputils-ping python2.7 python-pip tzdata unzip wget zulu-12 && \
usermod -u 99 nobody && \
usermod -g 100 nobody && \
mkdir -p /etc/my_init.d && \
mkdir -p /your-platform-install/defaults

ENV JAVA_HOME="/usr/lib/jvm/zulu-12-amd64"
ENV CATALINA_HOME="/opt/appdynamics/tomcat"
ENV CATALINA_PID="/opt/appdynamics/tomcat/temp/tomcat.pid"
ENV CATALINA_BASE="/opt/appdynamics/tomcat"

COPY firstrun.sh /etc/my_init.d/firstrun.sh
RUN chmod +x /etc/my_init.d/firstrun.sh
COPY --chown=nobody:users install-scripts/ /your-platform-install/defaults/install-scripts/
COPY --chown=nobody:users startup-scripts/ /your-platform-install/defaults/startup-scripts/