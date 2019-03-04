EUM_FILE=/config/appdynamics/EUM/eum-processor/bin/eum.sh
if [ -f "$EUM_FILE" ]; then
	echo "Starting EUM Server"
	sh $EUM_FILE start-events-service
else
	echo "EUM File not found here - $EUM_FILE"
fi