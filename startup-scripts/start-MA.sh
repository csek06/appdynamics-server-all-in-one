#!/bin/bash

# initialize variables
if [ -z $CONT_HOST ]; then
	CONT_HOST="localhost"
fi
if [ -z $CONT_PORT ]; then
	CONT_PORT="8090"
fi
if [ -z $CONT_KEY ]; then
	# Connect to Controller and obtain the AccessKey
	curl -s -c cookie.appd --user admin@customer1:appd -X GET http://$CONT_HOST:$CONT_PORT/controller/auth?action=login
	X_CSRF_TOKEN="$(grep X-CSRF-TOKEN cookie.appd | grep -oP '(X-CSRF-TOKEN\s)\K(.*)?(?=$)')"
	JSESSIONID_H=$(grep -oP '(JSESSIONID\s)\K(.*)?(?=$)' cookie.appd)
	CONT_KEY=$(curl http://$CONT_HOST:$CONT_PORT/controller/restui/user/account -H "X-CSRF-TOKEN: $X_CSRF_TOKEN" -H "Cookie: JSESSIONID=$JSESSIONID_H" | grep -oP '(?:accessKey\"\s\:\s\")\K(.*?)(?=\"\,)')
fi
if [ -z $ENABLE_SIM ]; then
	ENABLE_SIM="false"
fi
if [ -z $ENABLE_SIM_DOCKER ]; then
	ENABLE_SIM_DOCKER="false"
else
	# SIM and SIM Docker both need to be set to true
	if [[ $ENABLE_SIM_DOCKER = true ]]; then
		ENABLE_SIM=true
	fi
fi
if [ -z $ENABLE_CONTAINERIDASHOSTID ]; then
	ENABLE_CONTAINERIDASHOSTID="false"
fi

MA_FILE=/config/appdynamics/machine-agent/bin/machine-agent
if [ -f "$MA_FILE" ]; then
	echo "Starting Machine Agent"
	cd /config/appdynamics/machine-agent/
	./bin/machine-agent -Dappdynamics.controller.hostName=$CONT_HOST -Dappdynamics.controller.port=$CONT_PORT -Dappdynamics.agent.accountAccessKey=$CONT_KEY -Dappdynamics.sim.enabled=${ENABLE_SIM} -Dappdynamics.docker.enabled=${ENABLE_SIM_DOCKER} -Dappdynamics.docker.container.containerIdAsHostId.enabled=${ENABLE_CONTAINERIDASHOSTID} &
else
	echo "Machine Agent File not found here - $MA_FILE"
fi
