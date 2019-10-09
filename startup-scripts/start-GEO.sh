#!/bin/bash

GEO_FILE=$CATALINA_HOME/bin/startup.sh
if [ -f "$GEO_FILE" ]; then
	echo "Starting Custom Geo Server"
	chmod +x $GEO_FILE
	$GEO_FILE
else
	echo "Tomcat startup not found here - $GEO_FILE"
fi
