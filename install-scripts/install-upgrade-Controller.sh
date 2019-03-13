#!/bin/bash

# check if Controller is installed
if [ -f /config/appdynamics/controller/controller/bin/controller.sh ]; then
	cd /config/appdynamics/controller/controller/appserver/glassfish/domains/domain1/applications/controller/META-INF
	INSTALLED_VERSION=$(grep -oPz '(Controller\s*?v)\K(.*?)(?=\s.*?Build)' * | tr -d '\0')
	echo "Controller: $INSTALLED_VERSION is installed"
	# check for upgrade <code to be inserted>, however upgrade path needs to be followed EC > ES > EUM > Controller
else
	# check if enterprise console is installed
	if [ ! -f /config/appdynamics/platform/platform-admin/bin/platform-admin.sh ]; then
		EC_INSTALL_UPGRADE_FILE=/your-platform-install/install-scripts/install-upgrade-EC.sh
		if [ -f "$EC_INSTALL_UPGRADE_FILE" ]; then
			chmod +x $EC_INSTALL_UPGRADE_FILE
			bash $EC_INSTALL_UPGRADE_FILE
		else
			echo "EC install file not found here - $EC_INSTALL_UPGRADE_FILE"
		fi
	fi
	echo "Installing Controller and local database"
	cd /config/appdynamics/platform/platform-admin/bin
	./platform-admin.sh create-platform --name my-platform --installation-dir /config/appdynamics/controller
	./platform-admin.sh add-hosts --hosts $SERVERIP
	./platform-admin.sh submit-job --service controller --job install --args controllerPrimaryHost=$SERVERIP controllerAdminUsername=admin controllerAdminPassword=appd controllerRootUserPassword=appd mysqlRootPassword=appd
fi
