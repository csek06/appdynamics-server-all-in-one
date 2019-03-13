#!/bin/bash

# check if Events Service is installed
if [ -f /config/appdynamics/events-service/processor/bin/events-service.sh ]; then
	cd /config/appdynamics/events-service/processor
	INSTALLED_VERSION=$(grep -oPz '(version=)\K(.*?$)' version.txt)
	echo "Events Service: $INSTALLED_VERSION is installed"
	# check for upgrade <code to be inserted>, however upgrade path needs to be followed EC > ES > EUM > Controller
else
	# check if enterprise console is installed
	if [ ! -f /config/appdynamics/enterprise-console/platform-admin/bin/platform-admin.sh ]; then
		EC_INSTALL_UPGRADE_FILE=/your-platform-install/install-scripts/install-upgrade-EC.sh
		if [ -f "$EC_INSTALL_UPGRADE_FILE" ]; then
			chmod +x $EC_INSTALL_UPGRADE_FILE
			bash $EC_INSTALL_UPGRADE_FILE
		else
			echo "EC install file not found here - $EC_INSTALL_UPGRADE_FILE"
		fi
	fi
	echo "Installing Events Service"
	cd /config/appdynamics/enterprise-console/platform-admin/bin
	./platform-admin.sh install-events-service  --profile dev --hosts $SERVERIP
fi

