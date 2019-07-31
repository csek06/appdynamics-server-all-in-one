#!/bin/bash

# initialize variables
TOMCAT_FILE=/config/tomcat/bin/startup.sh
cd /config

if [ ! -f "$TOMCAT_FILE" ]; then
	TOMCAT_INSTALL_UPGRADE_FILE=/your-platform-install/install-scripts/install-upgrade-tomcat.sh
	if [ -f "$TOMCAT_INSTALL_UPGRADE_FILE" ]; then
		chmod +x $TOMCAT_INSTALL_UPGRADE_FILE
		bash $TOMCAT_INSTALL_UPGRADE_FILE
	else
		echo "Tomcat install file not found here - $TOMCAT_INSTALL_UPGRADE_FILE"
	fi
else
	echo "Tomcat already installed"
fi 