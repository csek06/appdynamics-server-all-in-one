#!/bin/bash

PA_FILE=$APPD_INSTALL_DIR/appdynamics/enterprise-console/platform-admin/bin/platform-admin.sh
if [ -f "$PA_FILE" ]; then
	echo "Starting Controller with DB"
	cd $APPD_INSTALL_DIR/appdynamics/enterprise-console/platform-admin/bin/
	./platform-admin.sh login --user-name admin --password appd
	
	# newer consoles do not use '--with-db' command
	EC_SUBVERSION=$(grep -oP '(\d+.\d+.)\K(\d+)(?=.\d+)' <<< $EC_INSTALLED_VERSION)
	echo "Enterprise Consolue Subversion = $EC_SUBVERSION"
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
