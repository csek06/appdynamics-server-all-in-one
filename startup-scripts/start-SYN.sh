#!/bin/bash

SYN_DIR=$APPD_INSTALL_DIR/appdynamics/synthetic-server
cd $SYN_DIR
	
SYN_INSTALLER="unix/deploy.sh"
if [ -f $SYN_INSTALLER ]; then
	# doesn't ship with a JRE checking if one is local
	if [ -f "$APPD_INSTALL_DIR/appdynamics/EUM/jre/bin/java" ]; then
		export JAVA_HOME=$APPD_INSTALL_DIR/appdynamics/EUM/jre
	fi
	echo "Starting the synthetic server"
	$SYN_INSTALLER start
fi