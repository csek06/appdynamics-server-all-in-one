#!/bin/bash

# check if Controller is installed
if [ -f /config/appdynamics/controller/bin/controller.sh ]; then
	cd /config/appdynamics/controller/appserver/glassfish/domains/domain1/applications/controller/META-INF
	INSTALLED_VERSION=$(grep -oP '(Controller\s*?v)\K(.*?)(?=\s.*?Build)' MANIFEST.MF)
	echo "Controller: $INSTALLED_VERSION is installed"
	# check for upgrade <code to be inserted>, however upgrade path needs to be followed EC > ES > EUM > Controller
else
	# check if enterprise console is installed
	if [ ! -f /config/appdynamics/enterprise-console/platform-admin/bin/platform-admin.sh ]; then
		echo "Please install Enterprise Console on Host and map appdata to /config"
	else
		echo "Installing Controller and local database"
		if [ -z $CONTROLLER_SIZE ]; then
			CONTROLLER_SIZE=demo
		fi
		cd /config/appdynamics/enterprise-console/platform-admin/bin
		./platform-admin.sh create-platform --name my-platform --installation-dir /config/appdynamics/
		./platform-admin.sh add-hosts --hosts $CONTROLLER_HOST
		./platform-admin.sh submit-job --service controller --job install --args controllerPrimaryHost=$CONTROLLER_HOST controllerAdminUsername=admin controllerAdminPassword=appd controllerRootUserPassword=appd mysqlRootPassword=appd controllerProfile=$CONTROLLER_SIZE
	fi
fi
