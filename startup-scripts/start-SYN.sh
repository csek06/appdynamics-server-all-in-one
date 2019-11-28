#!/bin/bash

SYN_DIR=$APPD_INSTALL_DIR/appdynamics/synthetic-server
cd $SYN_DIR
	
SYN_INSTALLER="unix/deploy.sh"
if [ -f $SYN_INSTALLER ]; then
	echo "Starting the synthetic server"
	$SYN_INSTALLER start
fi