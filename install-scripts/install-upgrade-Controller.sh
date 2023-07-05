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
		if [ -z $CONTROLLER_HOST ]; then
			CONTROLLER_HOST=$HOSTNAME
		fi
		if [ -z $CONTROLLER_SIZE ]; then
			CONTROLLER_SIZE=demo
		fi
		if [ "$CONTROLLER_SIZE" = "demo" ]; then
			echo "changing heap size to 4096m"
			sed -i "s|glassfish_max_heap_size = \"1024m\"|glassfish_max_heap_size = \"4096m\"|g" $APPD_INSTALL_DIR/appdynamics/enterprise-console/platform-admin/archives/controller/*/playbooks/controller-demo.groovy
		fi
		if [ "$CONTROLLER_SIZE" = "small" ]; then
			echo "changing heap size to 4096m"
			sed -i "s|glassfish_max_heap_size = \"1536m\"|glassfish_max_heap_size = \"4096m\"|g" $APPD_INSTALL_DIR/appdynamics/enterprise-console/platform-admin/archives/controller/*/playbooks/controller-small.groovy
		fi
		cd $APPD_INSTALL_DIR/appdynamics/enterprise-console/platform-admin/bin
		./platform-admin.sh create-platform --name my-platform --installation-dir $APPD_INSTALL_DIR/appdynamics/
		./platform-admin.sh add-hosts --hosts $CONTROLLER_HOST
		./platform-admin.sh submit-job --service controller --job install --args controllerPrimaryHost=$CONTROLLER_HOST controllerAdminUsername=admin controllerAdminPassword=appd controllerRootUserPassword=appd newDatabaseRootPassword=appd controllerProfile=$CONTROLLER_SIZE
		# Configuration to allow auto broadcast the actual host to agents - not the possible internal docker host
		if [ ! -z $DOCKER_HOST ]; then
			if [ ! "$CONTROLLER_HOST" = "$DOCKER_HOST" ]; then
				echo "Updating external broadcast hostname to $DOCKER_HOST"
				if [ -z $CONTROLLER_USE_HTTPS ]; then
					CONTROLLER_USE_HTTPS=false
				fi
				if [ "$CONTROLLER_USE_HTTPS" = true ]; then
					CONT_PROTO=https
					CONTROLLER_PORT=443
				else
					CONT_PROTO=http
					CONTROLLER_PORT=8090
				fi
				./platform-admin.sh update-service-configurations --service controller --job update-configs --args controllerExternalUrl=$CONT_PROTO://$DOCKER_HOST:$CONTROLLER_PORT
			fi
		fi
	fi
fi
