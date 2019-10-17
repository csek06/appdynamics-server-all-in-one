#!/bin/bash

# initialize variables
TOMCAT_HOME=$APPD_INSTALL_DIR/tomcat
mkdir -p $TOMCAT_HOME
cd $TOMCAT_HOME

wget http://apache.mirrors.tds.net/tomcat/tomcat-9/v9.0.22/bin/apache-tomcat-9.0.22.tar.gz
tar xzvf apache-tomcat-9.0.22.tar.gz -C $TOMCAT_HOME --strip-components=1
rm apache-tomcat-9.0.22.tar.gz

chmod -R g+r $TOMCAT_HOME/conf
chmod g+x $TOMCAT_HOME/conf