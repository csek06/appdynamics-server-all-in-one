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
    echo "adding '$appdserver' to '$destfile'"
    echo "$appdserver" >> "$destfile"
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

if [ ! -f /config/$FILENAME ]; then
  echo "Downloading AppDynamics Enterprise Console version '$VERSION'"
  TOKEN=$(curl -X POST -d '{"username": "'$AppdUser'","password": "'$AppdPass'","scopes": ["download"]}' https://identity.msrv.saas.appdynamics.com/v2.0/oauth/token | grep -oP '(\"access_token\"\:\s\")\K(.*?)(?=\"\,\s\")')
  curl -L -O -H "Authorization: Bearer ${TOKEN}" ${DOWNLOAD_PATH}
  echo "file downloaded"
  chmod +x ./$FILENAME
  
  echo "installing enterprise console"
  ./$FILENAME -q -varfile ~/response.varfile
  
  echo "installing controller and local database"
  cd /config/appdynamics/platform/platform-admin/bin
  ./platform-admin.sh create-platform --name my-platform --installation-dir /config/appdynamics/controller
  ./platform-admin.sh add-hosts --hosts localhost
  ./platform-admin.sh submit-job --service controller --job install --args controllerPrimaryHost=localhost controllerAdminUsername=admin controllerAdminPassword=appd controllerRootUserPassword=appd mysqlRootPassword=appd

  echo "installing events service"
  ./platform-admin.sh install-events-service  --profile dev --hosts localhost
  
  cd /config
  echo "Checking EUM server version"
  #Check the latest version on appdynamics
  curl -s -L -o tmpout.json "https://download.appdynamics.com/download/downloadfile/?version=&apm=&os=linux&platform_admin_os=&events=&eum=linux"
  EUMDOWNLOAD_PATH=$(grep -oP '(?:\"download_path\"\:\")(?!.*dmg)\K(.*?)(?=\"\,\")' tmpout.json)
  EUMFILENAME=$(grep -oP '(?:\"filename\"\:\")(?!.*dmg)\K(.*?)(?=\"\,\")' tmpout.json)
  rm -f tmpout.json
  
  echo "Downloading EUM server"
  echo "Downloading AppDynamics Enterprise Console version '$VERSION'"
  NEWTOKEN=$(curl -X POST -d '{"username": "'$AppdUser'","password": "'$AppdPass'","scopes": ["download"]}' https://identity.msrv.saas.appdynamics.com/v2.0/oauth/token | grep -oP '(\"access_token\"\:\s\")\K(.*?)(?=\"\,\s\")')
  curl -L -O -H "Authorization: Bearer ${NEWTOKEN}" ${EUMDOWNLOAD_PATH}
  echo "file downloaded"
  chmod +x ./$EUMFILENAME
  
  echo "Installing EUM server"
  ./$EUMFILENAME -q -varfile ~/response-eum.varfile
else
  echo "File found! Using existing version '$VERSION'"
  echo "Starting AppDynamics Services"
  cd /config/appdynamics/platform/platform-admin/bin
  ./platform-admin.sh start-platform-admin
  #./platform-admin.sh start-controller-db
  ./platform-admin.sh start-controller-appserver --with-db
  ./platform-admin.sh start-events-service
  
  cd /config/appdynamics/platform/EUM/eum-processor/
  ./bin/eum.sh start
fi
echo "Setting correct permissions"
chown -R nobody:users /config

echo "System Started"
