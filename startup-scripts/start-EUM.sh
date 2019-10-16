#!/bin/bash

# Utilizing AppD Shipped JRE
JAVA_JAR_FILE=$APPD_INSTALL_DIR/appdynamics/EUM/jre/bin/java
if [ -f $JAVA_JAR_FILE ]; then
	JAVA_HOME=$APPD_INSTALL_DIR/appdynamics/EUM/jre
fi

EUM_FILE=$APPD_INSTALL_DIR/appdynamics/EUM/eum-processor/bin/eum.sh
if [ -f "$EUM_FILE" ]; then
	echo "Starting EUM Server"
	cd $APPD_INSTALL_DIR/appdynamics/EUM/eum-processor/
	./bin/eum.sh start
	# Activate new EUM license file
	EUM_ACTIVATE_LICENSE_FILE=$APPD_SCRIPTS_DIR/startup-scripts/activate-eum-license.sh
	if [ -f "$EUM_ACTIVATE_LICENSE_FILE" ]; then
		chmod +x $EUM_ACTIVATE_LICENSE_FILE
		. $EUM_ACTIVATE_LICENSE_FILE
	else
		echo "EUM activate license file not found here - $EUM_ACTIVATE_LICENSE_FILE"
	fi
else
	echo "EUM File not found here - $EUM_FILE"
fi
