#!/bin/bash

PA_FILE=$APPD_INSTALL_DIR/appdynamics/enterprise-console/platform-admin/bin/platform-admin.sh
if [ -f "$PA_FILE" ]; then
	if [ -z $EC_INSTALLED_VERSION ]; then
		cd $APPD_INSTALL_DIR/appdynamics/enterprise-console/platform-admin/archives/platform-configuration/
		EC_INSTALLED_VERSION=$(grep -oP '(^platformVersion\:\s\")\K(.*?)(?=\"$)' * | tr -d '\0')
	fi
	echo "Login to Enterprise Console"
	cd $APPD_INSTALL_DIR/appdynamics/enterprise-console/platform-admin/bin/
	./platform-admin.sh login --user-name admin --password appd
	# newer consoles do not use '--with-db' command
	echo "Enterprise Console version = $EC_INSTALLED_VERSION" 
	EC_SUBVERSION=$(grep -oP '(\d+.\d+.)\K(\d+)(?=.\d+)' <<< $EC_INSTALLED_VERSION)
	echo "Enterprise Console Subversion = $EC_SUBVERSION"
	if [ $EC_SUBVERSION -gt 15 ]; then
		echo "Will issue standard start command"
		./platform-admin.sh start-controller-appserver
	else 
		echo "Will issue start command with db"
		./platform-admin.sh start-controller-appserver --with-db
	fi 
	
else
	echo "Platform Admin not found here - $PA_FILE"
fi
