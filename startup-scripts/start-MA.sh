#!/bin/bash

# initial testing variables
CONT_HOST=192.168.2.115
CONT_PORT=8090
CONT_KEY=

MA_FILE=/config/appdynamics/machine-agent/bin/machine-agent
if [ -f "$MA_FILE" ]; then
	echo "Starting Machine Agent"
	cd /config/appdynamics/machine-agent/
	./bin/machine-agent -Dappdynamics.controller.hostName=$CONT_HOST 
-Dappdynamics.controller.port=$CONT_PORT -Dappdynamics.agent.accountAccessKey=$CONT_KEY
else
	echo "Machine Agent File not found here - $MA_FILE"
fi
