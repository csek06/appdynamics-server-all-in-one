#!/bin/bash

# initialize variables
TOMCAT_HOME=/config/tomcat
mkdir -p $TOMCAT_HOME
cd $TOMCAT_HOME

if [ -f "$TOMCAT_HOME" ]; then
	export JAVA_HOME=/usr/lib/jvm/zulu-12-amd64
	export CATALINA_HOME=$TOMCAT_HOME
	export CATALINA_PID=$TOMCAT_HOME/temp/tomcat.pid
	export CATALINA_BASE=$TOMCAT_HOME
	wget http://www-us.apache.org/dist/tomcat/tomcat-9/v9.0.10/bin/apache-tomcat-9.0.10.tar.gz
	tar xzvf apache-tomcat-9.0.10.tar.gz -C $TOMCAT_HOME --strip-components=1

	useradd -s /bin/false -d $TOMCAT_HOME tomcat
	chgrp -R tomcat $TOMCAT_HOME
	chmod -R g+r $TOMCAT_HOME/conf
	chmod g+x $TOMCAT_HOME/conf
	chown -R tomcat $TOMCAT_HOME/webapps/ $TOMCAT_HOME/work/ $TOMCAT_HOME/temp/ $TOMCAT_HOME/logs/
else
	echo "Tomcat dir not found: ${TOMCAT_HOME}"
fi 