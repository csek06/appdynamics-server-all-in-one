#!/bin/bash

# initialize variables
TOMCAT_HOME=/config/tomcat
mkdir -p $TOMCAT_HOME
cd $TOMCAT_HOME

export JAVA_HOME=/usr/lib/jvm/zulu-12-amd64
export CATALINA_HOME=$TOMCAT_HOME
export CATALINA_PID=$TOMCAT_HOME/temp/tomcat.pid
export CATALINA_BASE=$TOMCAT_HOME
wget http://apache.mirrors.tds.net/tomcat/tomcat-9/v9.0.22/bin/apache-tomcat-9.0.22.tar.gz
tar xzvf apache-tomcat-9.0.22.tar.gz -C $TOMCAT_HOME --strip-components=1

useradd -s /bin/false -d $TOMCAT_HOME tomcat
chgrp -R tomcat $TOMCAT_HOME
chmod -R g+r $TOMCAT_HOME/conf
chmod g+x $TOMCAT_HOME/conf
chown -R tomcat $TOMCAT_HOME/webapps/ $TOMCAT_HOME/work/ $TOMCAT_HOME/temp/ $TOMCAT_HOME/logs/