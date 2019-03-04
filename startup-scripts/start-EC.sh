PA_FILE=/config/appdynamics/platform/platform-admin/bin/platform-admin.sh
if [ -f "$PA_FILE" ]; then
	echo "Starting Enterprise Console"
	cd /config/appdynamics/platform/platform-admin/bin/
	sh ./platform-admin.sh start-platform-admin
else
	echo "Platform Admin not found here - $PA_FILE"
fi