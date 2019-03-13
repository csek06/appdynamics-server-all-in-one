#!/bin/bash

# Check for host variables
if [ -z $CONTROLLER_HOST ]; then
	$CONTROLLER_HOST=localhost
fi
if [ -z $EUM_HOST ];then
	$EUM_HOST=localhost
fi
# Making post install configurations
# Sync Account Key between Controller and EUM Server - this should be in install
cd /config/appdynamics/EUM/eum-processor/
ES_EUM_KEY=$(curl --user admin@customer1:appd http://$CONTROLLER_HOST:8090/controller/rest/configuration?name=appdynamics.es.eum.key | grep -oP '(value\>)\K(.*?)(?=\<\/value)')
sed -i s/analytics.accountAccessKey=.*/analytics.accountAccessKey=$ES_EUM_KEY/ bin/eum.properties

# Change other EUM properties
sed -i s/onprem.dbUser=.*/onprem.dbUser=root/ bin/eum.properties
sed -i s/onprem.dbPassword=.*/onprem.dbPassword=appd/ bin/eum.properties
sed -i s/onprem.useEncryptedCredentials=.*/onprem.useEncryptedCredentials=false/ bin/eum.properties

# Connect EUM Server with Controller
curl -s -c cookie.appd --user root@system:appd -X GET http://$CONTROLLER_HOST:8090/controller/auth?action=login
X_CSRF_TOKEN="$(grep X-CSRF-TOKEN cookie.appd | grep -oP '(X-CSRF-TOKEN\s)\K(.*)?(?=$)')"
X_CSRF_TOKEN_HEADER="`if [ -n "$X_CSRF_TOKEN" ]; then echo "X-CSRF-TOKEN:$X_CSRF_TOKEN"; else echo ''; fi`"
curl -i -v -s -b cookie.appd -c cookie.appd2 -H "$X_CSRF_TOKEN_HEADER" -X POST "http://$CONTROLLER_HOST:8090/controller/rest/configuration?name=eum.es.host&value=http://$EUM_HOST:7001"
curl -i -v -s -b cookie.appd -c cookie.appd2 -H "$X_CSRF_TOKEN_HEADER" -X POST  "http://$CONTROLLER_HOST:8090/controller/rest/configuration?name=eum.cloud.host&value=http://$EUM_HOST:7001"
curl -i -v -s -b cookie.appd -c cookie.appd2 -H "$X_CSRF_TOKEN_HEADER" -X POST  "http://$CONTROLLER_HOST:8090/controller/rest/configuration?name=eum.beacon.host&value=http://$EUM_HOST:7001"
curl -i -v -s -b cookie.appd -c cookie.appd2 -H "$X_CSRF_TOKEN_HEADER" -X POST  "http://$CONTROLLER_HOST:8090/controller/rest/configuration?name=eum.beacon.https.host&value=https://$EUM_HOST:7002"
