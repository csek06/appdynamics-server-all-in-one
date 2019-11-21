#!/bin/bash

# check if Events Service is installed
if [ -f $APPD_INSTALL_DIR/appdynamics/events-service/processor/bin/events-service.sh ]; then
	cd $APPD_INSTALL_DIR/appdynamics/events-service/processor
	INSTALLED_VERSION=$(grep -oP '(version=)\K(.*?$)' version.txt)
	echo "Events Service: $INSTALLED_VERSION is installed"
	# check for upgrade <code to be inserted>, however upgrade path needs to be followed EC > ES > EUM > Controller
else
	# check if enterprise console is installed
	if [ ! -f $APPD_INSTALL_DIR/appdynamics/enterprise-console/platform-admin/bin/platform-admin.sh ]; then
		echo "Please install Enterprise Console on Host and map appdata to '$APPD_INSTALL_DIR'"
	else
		if [ -z $ES_SIZE ]; then
			ES_SIZE="dev"			
		fi
		if [ -z $CONTROLLER_HOST ]; then
			CONTROLLER_HOST=$HOSTNAME
		fi
		echo "Installing Events Service"
		cd $APPD_INSTALL_DIR/appdynamics/enterprise-console/platform-admin/bin
		./platform-admin.sh install-events-service  --profile $ES_SIZE --hosts $CONTROLLER_HOST
	fi
fi

