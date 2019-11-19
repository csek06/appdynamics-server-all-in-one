#!/bin/bash

# DA doesn't ship with a JRE checking if one is local
if [ -z $JAVA_HOME ]; then
	# check for other appd jre shipped components
	if [ -f "$APPD_INSTALL_DIR/appdynamics/machine-agent/jre/bin/java" ]; then
		export JAVA_HOME=$APPD_INSTALL_DIR/appdynamics/machine-agent/jre
	elif [ -f "$APPD_INSTALL_DIR/appdynamics/EUM/jre/bin/java" ]; then
		export JAVA_HOME=$APPD_INSTALL_DIR/appdynamics/EUM/jre
	elif [ -d "$APPD_INSTALL_DIR/appdynamics/jre" ]; then
		LATEST_JRE=$(ls -t $APPD_INSTALL_DIR/appdynamics/jre | head -1)
		export JAVA_HOME=$APPD_INSTALL_DIR/appdynamics/jre/$LATEST_JRE
	else
		echo "JAVA_HOME not set - please ensure Java is installed"
	fi
fi

if [ ! -z $JAVA_HOME ]; then
	# initialize variables
	DATABASE_AGENT_HOME=$APPD_INSTALL_DIR/appdynamics/database-agent
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
			CONTROLLER_KEY=$(curl -s http://$CONTROLLER_HOST:$CONTROLLER_PORT/controller/restui/user/account -H "X-CSRF-TOKEN: $X_CSRF_TOKEN" -H "Cookie: JSESSIONID=$JSESSIONID_H" | grep -oP '(?:accessKey\"\s\:\s\")\K(.*?)(?=\"\,)')
			rm cookie.appd
		else
			echo "Couldn't connect DA to controller to obtain controller key -- NOT starting DA"
			exit 1
		fi
	fi

	if [ ! -z $CONTROLLER_KEY ]; then
		if [ -z $DB_AGENT_NAME ]; then
			DB_AGENT_NAME=$(hostname)
		fi 
		if [ -z $DB_ENABLE_CONTAINERIDASHOSTID ]; then
			DB_ENABLE_CONTAINERIDASHOSTID="false"
		fi
		DA_PROPERTIES="-Dappdynamics.controller.hostName=${CONTROLLER_HOST}"
		DA_PROPERTIES="$DA_PROPERTIES -Dappdynamics.controller.port=${CONTROLLER_PORT}"
		#DA_PROPERTIES="$DA_PROPERTIES -Dappdynamics.agent.accountName=${ACCOUNT_NAME}"
		DA_PROPERTIES="$DA_PROPERTIES -Dappdynamics.agent.accountAccessKey=${CONTROLLER_KEY}"
		#DA_PROPERTIES="$DA_PROPERTIES -Dappdynamics.controller.ssl.enabled=${CONTROLLER_SSL_ENABLED}"
		DA_PROPERTIES="$DA_PROPERTIES -Dappdynamics.docker.container.containerIdAsHostId.enabled=${DB_ENABLE_CONTAINERIDASHOSTID}"
		DA_PROPERTIES="$DA_PROPERTIES -Ddbagent.name=${DB_AGENT_NAME}"

		DA_FILE=$DATABASE_AGENT_HOME/start-dbagent
		if [ -f "$DA_FILE" ]; then
			echo "Starting Database Agent"
			# Start Database Agent
			#echo java ${DA_PROPERTIES} -jar ${DA_FILE}
			#java ${DA_PROPERTIES} -jar ${DA_FILE}
			echo ${DA_FILE} ${DA_PROPERTIES}
			chmod +x ${DA_FILE}
			$DA_FILE ${DA_PROPERTIES} &
		else
			echo "Database Agent File not found here - $DA_FILE"
		fi
	fi
fi 