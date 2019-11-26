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
		if [ -z $DOCKER_HOST ]; then
			CONTROLLER_HOST=$DOCKER_HOST
		fi
		if [ -z $CONTROLLER_HOST ]; then
			CONTROLLER_HOST=$HOSTNAME
		fi
		echo "Installing Events Service"
		cd $APPD_INSTALL_DIR/appdynamics/enterprise-console/platform-admin/bin
		./platform-admin.sh install-events-service  --profile $ES_SIZE --hosts $CONTROLLER_HOST
		
		# Configuration to allow auto broadcast the actual ES host to agents - not the possible internal docker host
		if [ -z $DOCKER_HOST ]; then
			if [ "$CONTROLLER_HOST" != "$DOCKER_HOST" ]; then
				echo "Updating external broadcast ES hostname to $DOCKER_HOST"
				if [ "$PROXY" = "true" ]; then
					ES_PORT=80
				else
					ES_PORT=9080
				fi
				# Connect EUM Server with Controller
				curl -s -c cookie.appd --user root@system:appd -X GET http://$CONTROLLER_HOST:$CONTROLLER_PORT/controller/auth?action=login
				if [ -f "cookie.appd" ]; then
					X_CSRF_TOKEN="$(grep X-CSRF-TOKEN cookie.appd | grep -oP '(X-CSRF-TOKEN\s)\K(.*)?(?=$)')"
					X_CSRF_TOKEN_HEADER="`if [ -n "$X_CSRF_TOKEN" ]; then echo "X-CSRF-TOKEN:$X_CSRF_TOKEN"; else echo ''; fi`"
					ES_HOST_VALUE="name=appdynamics.on.premise.event.service.url&value=http://$DOCKER_HOST:$ES_PORT"
					
					echo "Setting $ES_HOST_VALUE in Controller"
					curl -s -b cookie.appd -c cookie.appd2 --output /dev/null -H "$X_CSRF_TOKEN_HEADER" -X POST "http://$CONTROLLER_HOST:$CONTROLLER_PORT/controller/rest/configuration?$ES_HOST_VALUE"
				else
					echo "Couldn't connect to controller host to update the Event Service URL to $DOCKER_HOST"
				fi
			fi
		fi
	fi
fi

