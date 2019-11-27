#!/bin/bash

# Check for host variables
if [ -z $CONTROLLER_HOST ]; then
	CONTROLLER_HOST=$HOSTNAME
fi
if [ -z $CONTROLLER_PORT ]; then
	CONTROLLER_PORT="8090"
fi

# Connect Synthetic Server with Controller
curl -s -c cookie.appd --user root@system:appd -X GET http://$CONTROLLER_HOST:$CONTROLLER_PORT/controller/auth?action=login
if [ -f "cookie.appd" ]; then
	X_CSRF_TOKEN="$(grep X-CSRF-TOKEN cookie.appd | grep -oP '(X-CSRF-TOKEN\s)\K(.*)?(?=$)')"
	X_CSRF_TOKEN_HEADER="`if [ -n "$X_CSRF_TOKEN" ]; then echo "X-CSRF-TOKEN:$X_CSRF_TOKEN"; else echo ''; fi`"
	if [ ! -z $DOCKER_HOST ]; then
		SYN_INSTALL_VALUE="name=eum.synthetic.onprem.installation&value=true"
		SYN_SCHEDULER_HOST="name=eum.synthetic.scheduler.host&value=http://$DOCKER_HOST:12101"
		SYN_SHEPHERD_HOST="name=eum.synthetic.shepherd.host&value=http://$DOCKER_HOST:10101"
	else
		SYN_INSTALL_VALUE="name=eum.synthetic.onprem.installation&value=true"
		SYN_SCHEDULER_HOST="name=eum.synthetic.scheduler.host&value=http://$HOSTNAME:12101"
		SYN_SHEPHERD_HOST="name=eum.synthetic.shepherd.host&value=http://$HOSTNAME:10101"
	fi
	echo "Setting $SYN_INSTALL_VALUE in Controller"
	curl -s -b cookie.appd -c cookie.appd2 --output /dev/null -H "$X_CSRF_TOKEN_HEADER" -X POST "http://$CONTROLLER_HOST:$CONTROLLER_PORT/controller/rest/configuration?$SYN_INSTALL_VALUE"
	echo "Setting $SYN_SCHEDULER_HOST in Controller"
	curl -s -b cookie.appd -c cookie.appd2 --output /dev/null -H "$X_CSRF_TOKEN_HEADER" -X POST "http://$CONTROLLER_HOST:$CONTROLLER_PORT/controller/rest/configuration?$SYN_SCHEDULER_HOST"
	echo "Setting $SYN_SHEPHERD_HOST in Controller"
	curl -s -b cookie.appd -c cookie.appd2 --output /dev/null -H "$X_CSRF_TOKEN_HEADER" -X POST "http://$CONTROLLER_HOST:$CONTROLLER_PORT/controller/rest/configuration?$SYN_SHEPHERD_HOST"
	rm cookie.appd
	rm cookie.appd2
else
	echo "Couldn't connect Synthetic Server to controller to set Synthetic Server properties"
fi
