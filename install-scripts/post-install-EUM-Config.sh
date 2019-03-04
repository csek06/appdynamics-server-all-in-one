#!/bin/bash

# Making post install configurations
# Sync Account Key between Controller and EUM Server - this should be in install
cd /config/appdynamics/EUM/eum-processor/
ES_EUM_KEY=$(curl --user admin@customer1:appd http://$SERVERIP:8090/controller/rest/configuration?name=appdynamics.es.eum.key | grep -oP '(value\>)\K(.*?)(?=\<\/value)')
sed -i s/analytics.accountAccessKey=.*/analytics.accountAccessKey=$ES_EUM_KEY/ bin/eum.properties

# Change other EUM properties
sed -i s/onprem.dbUser=.*/onprem.dbUser=root/ bin/eum.properties
sed -i s/onprem.dbPassword=.*/onprem.dbPassword=appd/ bin/eum.properties
sed -i s/onprem.useEncryptedCredentials=.*/onprem.useEncryptedCredentials=false/ bin/eum.properties

# Connect EUM Server with Controller
curl -s -c cookie.appd --user root@system:appd -X GET http://$SERVERIP:8090/controller/auth?action=login
X_CSRF_TOKEN="$(grep X-CSRF-TOKEN cookie.appd|rev|cut -d$'\t' -f1|rev)"
X_CSRF_TOKEN_HEADER="`if [ -n "$X_CSRF_TOKEN" ]; then echo "X-CSRF-TOKEN:$X_CSRF_TOKEN"; else echo ''; fi`"
curl -i -v -s -b cookie.appd -c cookie.appd2 -H "$X_CSRF_TOKEN_HEADER" -X POST "http://$SERVERIP:8090/controller/rest/configuration?name=eum.es.host&value=http://$1:7001"
curl -i -v -s -b cookie.appd -c cookie.appd2 -H "$X_CSRF_TOKEN_HEADER" -X POST  "http://$SERVERIP:8090/controller/rest/configuration?name=eum.cloud.host&value=http://$1:7001"
curl -i -v -s -b cookie.appd -c cookie.appd2 -H "$X_CSRF_TOKEN_HEADER" -X POST  "http://$SERVERIP:8090/controller/rest/configuration?name=eum.beacon.host&value=http://$1:7001"
curl -i -v -s -b cookie.appd -c cookie.appd2 -H "$X_CSRF_TOKEN_HEADER" -X POST  "http://$SERVERIP:8090/controller/rest/configuration?name=eum.beacon.https.host&value=https://$1:7002"