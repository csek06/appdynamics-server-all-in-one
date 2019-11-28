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


# Check to see if the EUM server is already up...
EUM_STATUS="$(curl -s $EUM_HOST:7001/eumaggregator/ping)"
if [ ! "$EUM_STATUS" = "ping" ]; then
	# Check to see if controller is up already
	# Connect EUM Server with Controller
	curl -s -c cookie.appd --user root@system:appd -X GET http://$CONTROLLER_HOST:$CONTROLLER_PORT/controller/auth?action=login
	if [ -f "cookie.appd" ]; then
		# Utilizing AppD Shipped JRE
		JAVA_JAR_FILE=$APPD_INSTALL_DIR/appdynamics/EUM/jre/bin/java
		if [ -f $JAVA_JAR_FILE ]; then
			export JAVA_HOME=$APPD_INSTALL_DIR/appdynamics/EUM/jre
		fi
		
		echo "Starting the DB first"
		EUM_DB_DIR=$APPD_INSTALL_DIR/appdynamics/EUM/orcha/orcha-master/bin
		cd $EUM_DB_DIR
		EUM_DB_FILE=orcha-master
		if [ -f $EUM_DB_FILE ]; then
			./$EUM_DB_FILE -d mysql.groovy -p ../../playbooks/mysql-orcha/start-mysql.orcha -o ../conf/orcha.properties -c local
		else
			echo "DB File: $EUM_DB_FILE not found here: $EUM_DB_DIR"
		fi
		EUM_FILE=$APPD_INSTALL_DIR/appdynamics/EUM/eum-processor/bin/eum.sh
		if [ -f "$EUM_FILE" ]; then
			echo "Starting EUM Server"
			cd $APPD_INSTALL_DIR/appdynamics/EUM/eum-processor/
			EUM_START_FILE="bin/eum.sh"
			./$EUM_START_FILE start
		else
			echo "EUM File not found here - $EUM_FILE"
		fi
		# Activate EUM license file
		EUM_ACTIVATE_LICENSE_FILE=$APPD_SCRIPTS_DIR/startup-scripts/activate-eum-license.sh
		if [ -f "$EUM_ACTIVATE_LICENSE_FILE" ]; then
			chmod +x $EUM_ACTIVATE_LICENSE_FILE
			. $EUM_ACTIVATE_LICENSE_FILE
		else
			echo "EUM activate license file not found here - $EUM_ACTIVATE_LICENSE_FILE"
		fi
	else
		echo "Controller Server is not up -- not attempting start"
		exit 1
	fi 
else
	echo "EUM Server is already up -- not attempting another start"
fi
