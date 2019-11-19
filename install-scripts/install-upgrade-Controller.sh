#!/bin/bash

# check if Controller is installed
if [ -f $APPD_INSTALL_DIR/appdynamics/controller/bin/controller.sh ]; then
	cd $APPD_INSTALL_DIR/appdynamics/controller/appserver/glassfish/domains/domain1/applications/controller/META-INF
	INSTALLED_VERSION=$(grep -oP '(Controller\s*?v)\K(.*?)(?=\s.*?Build)' MANIFEST.MF)
	echo "Controller: $INSTALLED_VERSION is installed"
	# check for upgrade <code to be inserted>, however upgrade path needs to be followed EC > ES > EUM > Controller
else
	# check if enterprise console is installed
	if [ ! -f $APPD_INSTALL_DIR/appdynamics/enterprise-console/platform-admin/bin/platform-admin.sh ]; then
		echo "Please install Enterprise Console on Host and map appdata to '$APPD_INSTALL_DIR'"
	else
		echo "Installing Controller and local database"
		if [ -z $CONTROLLER_SIZE ]; then
			CONTROLLER_SIZE=demo
		fi
		cd $APPD_INSTALL_DIR/appdynamics/enterprise-console/platform-admin/bin
		./platform-admin.sh create-platform --name my-platform --installation-dir $APPD_INSTALL_DIR/appdynamics/
		./platform-admin.sh add-hosts --hosts $CONTROLLER_HOST
		./platform-admin.sh submit-job --service controller --job install --args controllerPrimaryHost=$CONTROLLER_HOST controllerAdminUsername=admin controllerAdminPassword=appd controllerRootUserPassword=appd newDatabaseRootPassword=appd controllerProfile=$CONTROLLER_SIZE
	fi
fi
