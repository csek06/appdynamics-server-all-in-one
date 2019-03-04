PA_FILE=/config/appdynamics/platform/platform-admin/bin/platform-admin.sh
if [ -f "$PA_FILE" ]; then
	echo "Starting Events Service"
	cd /config/appdynamics/platform/platform-admin/bin/
	sh $PA_FILE start-events-service
else
	echo "Platform Admin not found here - $PA_FILE"
fi