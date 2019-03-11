#!/bin/bash

# check if Controller is installed
if [ -f /config/appdynamics/controller/controller/bin/controller.sh ]; then
	cd /config/appdynamics/platform/platform-admin/archives/platform-configuration/
	INSTALLED_VERSION=$(grep -oPz '(controller\"\s*?version\:\s\")\K(.*?)(?=\"\s.*?build)' * | tr -d '\0')
	echo "Controller: $INSTALLED_VERSION is installed"
	# check for upgrade <code to be inserted>, however upgrade path needs to be followed EC > ES > EUM > Controller
else
	echo "Installing Controller and local database"
	cd /config/appdynamics/platform/platform-admin/bin
	./platform-admin.sh create-platform --name my-platform --installation-dir /config/appdynamics/controller
	./platform-admin.sh add-hosts --hosts localhost
	./platform-admin.sh submit-job --service controller --job install --args controllerPrimaryHost=localhost controllerAdminUsername=admin controllerAdminPassword=appd controllerRootUserPassword=appd mysqlRootPassword=appd
fi
