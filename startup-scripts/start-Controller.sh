#!/bin/bash

PA_FILE=/config/appdynamics/enterprise-console/platform-admin/bin/platform-admin.sh
if [ -f "$PA_FILE" ]; then
	echo "Starting Controller with DB"
	cd /config/appdynamics/enterprise-console/platform-admin/bin/
	./platform-admin.sh login --user-name admin --password appd
	./platform-admin.sh start-controller-appserver --with-db
else
	echo "Platform Admin not found here - $PA_FILE"
fi
