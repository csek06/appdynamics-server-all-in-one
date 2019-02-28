#!/bin/bash

#Get docker env timezone and set system timezone
echo "setting the correct local time"
echo $TZ > /etc/timezone
export DEBCONF_NONINTERACTIVE_SEEN=true DEBIAN_FRONTEND=noninteractive
dpkg-reconfigure tzdata

#Configure Appd for IP address given as environment variable
destfile=/root/response.varfile
if [ -f "$destfile" ]
then 
    appdserver="serverHostName=${SERVERIP}"
    echo "setting '$appdserver' in '$destfile'"
    #echo "$appdserver" >> "$destfile"
    sed -i s/serverHostName=.*/$appdserver/ $destfile
fi

cd /config
if [ ! -z $VERSION ]; then
  echo "Manual version override:" $VERSION
  FILENAME="platform-setup-x64-linux-'$VERSION'.sh"
  echo "Filename: $FILENAME"
else
  #Check the latest version on appdynamics
  curl -s -L -o tmpout.json "https://download.appdynamics.com/download/downloadfile/?version=&apm=&os=linux&platform_admin_os=linux&events=&eum="
  VERSION=$(grep -oP '(\"version\"\:\")\K(.*?)(?=\"\,\")' tmpout.json)
  DOWNLOAD_PATH=$(grep -oP '(\"download_path\"\:\")\K(.*?)(?=\"\,\")' tmpout.json)
  FILENAME=$(grep -oP '(\"filename\"\:\")\K(.*?)(?=\"\,\")' tmpout.json)
  echo "Latest version on appdynamics is" $VERSION
  rm -f tmpout.json
fi

# check if enterprise console is installed
if [ -f /config/appdynamics/platform/platform-admin/bin/platform-admin.sh ]; then
  echo "Enterprise Console is installed"
else
  # check if user didn't downloaded latest Enterprise Console binary
  if [ ! -f /config/$FILENAME ]; then
    echo "Downloading AppDynamics Enterprise Console version '$VERSION'"
    TOKEN=$(curl -X POST -d '{"username": "'$AppdUser'","password": "'$AppdPass'","scopes": ["download"]}' https://identity.msrv.saas.appdynamics.com/v2.0/oauth/token | grep -oP '(\"access_token\"\:\s\")\K(.*?)(?=\"\,\s\")')
    curl -L -O -H "Authorization: Bearer ${TOKEN}" ${DOWNLOAD_PATH}
    echo "file downloaded"
  else
    echo "Found latest Enterprise Console '$FILENAME' in /config/ "
  fi
  # installing ent console
  echo "Installing Enterprise Console"
  chmod +x ./$FILENAME
  ./$FILENAME -q -varfile ~/response.varfile
  # assuming install went fine
  rm -f ./$FILENAME
fi

# check if Controller is installed
if [ -f /config/appdynamics/controller/controller/bin/controller.sh ]; then
  echo "Controller is installed"
else
  echo "Installing Controller and local database"
  cd /config/appdynamics/platform/platform-admin/bin
  ./platform-admin.sh create-platform --name my-platform --installation-dir /config/appdynamics/controller
  ./platform-admin.sh add-hosts --hosts localhost
  ./platform-admin.sh submit-job --service controller --job install --args controllerPrimaryHost=localhost controllerAdminUsername=admin controllerAdminPassword=appd controllerRootUserPassword=appd mysqlRootPassword=appd
fi

# check if Events Service is installed
if [ -f /config/appdynamics/controller/events-service/processor/bin/events-service.sh ]; then
  echo "Events Service is installed"
else
  echo "Installing Events Service"
  cd /config/appdynamics/platform/platform-admin/bin
  ./platform-admin.sh install-events-service  --profile dev --hosts localhost
fi

# check if EUM Server is installed
if [ -f /config/appdynamics/EUM/eum-processor/bin/eum.sh ]; then
  echo "EUM Server is installed"
else
  # Check latest EUM server version
  cd /config
  echo "Checking EUM server version"
  #Check the latest version on appdynamics
  curl -s -L -o tmpout.json "https://download.appdynamics.com/download/downloadfile/?version=&apm=&os=linux&platform_admin_os=&events=&eum=linux"
  EUMDOWNLOAD_PATH=$(grep -oP '(?:\"download_path\"\:\")(?!.*dmg)\K(.*?)(?=\"\,\")' tmpout.json)
  EUMFILENAME=$(grep -oP '(?:\"filename\"\:\")(?!.*dmg)\K(.*?)(?=\"\,\")' tmpout.json)
  rm -f tmpout.json
  # check if user downloaded latest EUM server binary
  if [ -f /config/$EUMFILENAME ]; then
    echo "Found latest EUM Server '$EUMFILENAME' in /config/ "
  else
    echo "Didn't find '$EUMFILENAME' in /config/ - downloading"
    NEWTOKEN=$(curl -X POST -d '{"username": "'$AppdUser'","password": "'$AppdPass'","scopes": ["download"]}' https://identity.msrv.saas.appdynamics.com/v2.0/oauth/token | grep -oP '(\"access_token\"\:\s\")\K(.*?)(?=\"\,\s\")')
    curl -L -O -H "Authorization: Bearer ${NEWTOKEN}" ${EUMDOWNLOAD_PATH}
    echo "file downloaded"
  fi
  chmod +x ./$EUMFILENAME
  echo "Installing EUM server"
  ./$EUMFILENAME -q -varfile ~/response-eum.varfile
  # assuming install went fine
  rm -f ./$EUMFILENAME
  # Making post install configurations
  # Sync Account Key between Controller and EUM Server - this should be in install
  cd /config/appdynamics/EUM/eum-processor/
  # daves command
  #curl --user admin@customer1:appd http://$SERVERIP:8090/controller/rest/configuration?name=appdynamics.es.eum.key | xmllint --xpath "//configuration-items/configuration-item/value/text()" -  > es_eum_key.out
  #ES_EUM_KEY=$(cat es_eum_key.out)
  # Chris's command that doesn't require additional package
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
fi

echo "Setting correct permissions"
chown -R nobody:users /config

# Start the AppDynamics Services
echo "Starting AppDynamics Services"
cd /config/appdynamics/platform/platform-admin/bin
echo "Starting Enterprise Console"
./platform-admin.sh start-platform-admin
echo "Starting Controller with DB"
./platform-admin.sh start-controller-appserver --with-db
echo "Starting Events Service"
./platform-admin.sh start-events-service
echo "Starting EUM Server"
cd /config/appdynamics/EUM/eum-processor/
./bin/eum.sh start

# Checking for license file and activating eum (outside of install so if user placed a new license file)
LICENSE_OG="/config/license.lic"
LICENSE_LOC="/config/appdynamics/controller/controller/license.lic"
if [ -f $LICENSE_OG ]; then
  mv -f $LICENSE_OG $LICENSE_LOC
fi
if [ -f $LICENSE_LOC ]; then
  /config/appdynamics/EUM/eum-processor/bin/provision-license $LICENSE_LOC
fi

echo "System Started"
