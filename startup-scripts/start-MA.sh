#!/bin/bash

# initialize variables
MACHINE_AGENT_HOME=$APPD_INSTALL_DIR/appdynamics/machine-agent
if [ -z $CONTROLLER_HOST ]; then
	CONTROLLER_HOST="localhost"
fi
if [ -z $CONTROLLER_PORT ]; then
	CONTROLLER_PORT="8090"
fi
if [ -z $CONTROLLER_KEY ]; then
	# Connect to Controller and obtain the AccessKey
	curl -s -c cookie.appd --user admin@customer1:appd -X GET http://$CONTROLLER_HOST:$CONTROLLER_PORT/controller/auth?action=login
	if [ -f "cookie.appd" ]; then
		X_CSRF_TOKEN="$(grep X-CSRF-TOKEN cookie.appd | grep -oP '(X-CSRF-TOKEN\s)\K(.*)?(?=$)')"
		JSESSIONID_H=$(grep -oP '(JSESSIONID\s)\K(.*)?(?=$)' cookie.appd)
		CONTROLLER_KEY=$(curl http://$CONTROLLER_HOST:$CONTROLLER_PORT/controller/restui/user/account -H "X-CSRF-TOKEN: $X_CSRF_TOKEN" -H "Cookie: JSESSIONID=$JSESSIONID_H" | grep -oP '(?:accessKey\"\s\:\s\")\K(.*?)(?=\"\,)')
		rm cookie.appd
	else
		echo "Couldn't connect to controller to obtain controller key"
	fi
fi
if [ -z $MA_AGENT_NAME ]; then
	MA_AGENT_NAME=$(hostname)
fi 
if [ -z $MA_ENABLE_SIM ]; then
	MA_ENABLE_SIM="false"
fi
if [ -z $MA_ENABLE_SIM_DOCKER ]; then
	MA_ENABLE_SIM_DOCKER="false"
else
	# SIM and SIM Docker both need to be set to true
	if [ "$MA_ENABLE_SIM_DOCKER" = "true" ]; then
		MA_ENABLE_SIM="true"
	fi
fi
if [ -z $MA_ENABLE_CONTAINERIDASHOSTID ]; then
	MA_ENABLE_CONTAINERIDASHOSTID="false"
fi
MA_PROPERTIES="-Dappdynamics.controller.hostName=${CONTROLLER_HOST}"
MA_PROPERTIES="$MA_PROPERTIES -Dappdynamics.controller.port=${CONTROLLER_PORT}"
#MA_PROPERTIES="$MA_PROPERTIES -Dappdynamics.agent.accountName=${ACCOUNT_NAME}"
MA_PROPERTIES="$MA_PROPERTIES -Dappdynamics.agent.accountAccessKey=${CONTROLLER_KEY}"
#MA_PROPERTIES="$MA_PROPERTIES -Dappdynamics.controller.ssl.enabled=${CONTROLLER_SSL_ENABLED}"
MA_PROPERTIES="$MA_PROPERTIES -Dappdynamics.sim.enabled=${MA_ENABLE_SIM}"
MA_PROPERTIES="$MA_PROPERTIES -Dappdynamics.docker.enabled=${MA_ENABLE_SIM_DOCKER}"
MA_PROPERTIES="$MA_PROPERTIES -Dappdynamics.docker.container.containerIdAsHostId.enabled=${MA_ENABLE_CONTAINERIDASHOSTID}"
MA_PROPERTIES="$MA_PROPERTIES -Ddbagent.name=${MA_AGENT_NAME}"

MA_FILE=$APPD_INSTALL_DIR/appdynamics/machine-agent/bin/machine-agent
MA_PID_FILE=$MACHINE_AGENT_HOME/machine-agent.id
if [ -f "$MA_FILE" ]; then
	if [ -f "$MA_PID_FILE" ]; then
		rm $MA_PID_FILE
	fi
	echo "Starting Machine Agent"
	# Start Machine Agent
	#echo java ${MA_PROPERTIES} -jar ${MACHINE_AGENT_HOME}/machineagent.jar
	#java ${MA_PROPERTIES} -jar ${MACHINE_AGENT_HOME}/machineagent.jar
	echo $MA_FILE -d ${MA_PROPERTIES} -p ${MA_PID_FILE}
	chmod +x $MA_FILE
	$MA_FILE -d ${MA_PROPERTIES} -p ${MA_PID_FILE}
else
	echo "Machine Agent File not found here - $MA_FILE"
fi
