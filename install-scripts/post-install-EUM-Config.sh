#!/bin/bash

# Check for host variables
if [ -z $CONTROLLER_HOST ]; then
	CONTROLLER_HOST=$HOSTNAME
fi
if [ -z $EUM_HOST ]; then
	EUM_HOST=$HOSTNAME
fi
if [ -z $CONTROLLER_PORT ]; then
	CONTROLLER_PORT="8090"
fi
# Making post install configurations
cd $APPD_INSTALL_DIR/appdynamics/EUM/eum-processor/

# Change other EUM properties
sed -i s/onprem.dbUser=.*/onprem.dbUser=root/ bin/eum.properties
sed -i s/onprem.dbPassword=.*/onprem.dbPassword=appd/ bin/eum.properties
sed -i s/onprem.useEncryptedCredentials=.*/onprem.useEncryptedCredentials=false/ bin/eum.properties

# Connect EUM Server with Controller
curl -s -c cookie.appd --user root@system:appd -X GET http://$CONTROLLER_HOST:$CONTROLLER_PORT/controller/auth?action=login
if [ -f "cookie.appd" ]; then
	X_CSRF_TOKEN="$(grep X-CSRF-TOKEN cookie.appd | grep -oP '(X-CSRF-TOKEN\s)\K(.*)?(?=$)')"
	X_CSRF_TOKEN_HEADER="`if [ -n "$X_CSRF_TOKEN" ]; then echo "X-CSRF-TOKEN:$X_CSRF_TOKEN"; else echo ''; fi`"
	if [ ! -z $DOCKER_HOST ]; then
		ES_HOST_VALUE="name=eum.es.host&value=http://$DOCKER_HOST:9080"
		EUM_CLOUD_HOST="name=eum.cloud.host&value=http://$DOCKER_HOST:7001"
		EUM_BEACON_HTTP_HOST="name=eum.beacon.host&value=http://$DOCKER_HOST:7001"
		EUM_BEACON_HTTPS_HOST="name=eum.beacon.https.host&value=https://$DOCKER_HOST:7002"
	else
		ES_HOST_VALUE="name=eum.es.host&value=http://$EVENTS_SERVICE_HOST:9080"
		EUM_CLOUD_HOST="name=eum.cloud.host&value=http://$EUM_HOST:7001"
		EUM_BEACON_HTTP_HOST="name=eum.beacon.host&value=http://$EUM_HOST:7001"
		EUM_BEACON_HTTPS_HOST="name=eum.beacon.https.host&value=https://$EUM_HOST:7002"
	fi
	ES_HOST_VALUE="name=eum.es.host&value=http://$EVENTS_SERVICE_HOST:9080"
	EUM_CLOUD_HOST="name=eum.cloud.host&value=http://$EUM_HOST:7001"
	EUM_BEACON_HTTP_HOST="name=eum.beacon.host&value=http://$EUM_HOST:7001"
	EUM_BEACON_HTTPS_HOST="name=eum.beacon.https.host&value=https://$EUM_HOST:7002"
	echo "Setting $ES_HOST_VALUE in Controller"
	curl -s -b cookie.appd -c cookie.appd2 --output /dev/null -H "$X_CSRF_TOKEN_HEADER" -X POST "http://$CONTROLLER_HOST:$CONTROLLER_PORT/controller/rest/configuration?$ES_HOST_VALUE"
	echo "Setting $EUM_CLOUD_HOST in Controller"
	curl -s -b cookie.appd -c cookie.appd2 --output /dev/null -H "$X_CSRF_TOKEN_HEADER" -X POST "http://$CONTROLLER_HOST:$CONTROLLER_PORT/controller/rest/configuration?$EUM_CLOUD_HOST"
	echo "Setting $EUM_BEACON_HTTP_HOST in Controller"
	curl -s -b cookie.appd -c cookie.appd2 --output /dev/null -H "$X_CSRF_TOKEN_HEADER" -X POST "http://$CONTROLLER_HOST:$CONTROLLER_PORT/controller/rest/configuration?$EUM_BEACON_HTTP_HOST"
	echo "Setting $EUM_BEACON_HTTPS_HOST in Controller"
	curl -s -b cookie.appd -c cookie.appd2 --output /dev/null -H "$X_CSRF_TOKEN_HEADER" -X POST "http://$CONTROLLER_HOST:$CONTROLLER_PORT/controller/rest/configuration?$EUM_BEACON_HTTPS_HOST"
	rm cookie.appd
	rm cookie.appd2
else
	echo "Couldn't connect EUM to controller to set EUM properties"
fi
