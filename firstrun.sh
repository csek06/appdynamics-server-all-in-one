#!/bin/bash

#Get docker env timezone and set system timezone
echo "setting the correct local time"
echo $TZ > /etc/timezone
export DEBCONF_NONINTERACTIVE_SEEN=true DEBIAN_FRONTEND=noninteractive
dpkg-reconfigure tzdata
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
  #VERSION=${VERSION:1}
  echo "Latest version on appdynamics is" $VERSION
  rm -f tmpout.json
fi

if [ ! -f /config/$FILENAME ]; then
  echo "Installing version '$VERSION'"
  TOKEN=$(curl -X POST -d '{"username": "'$AppdUser'","password": "'$AppdPass'","scopes": ["download"]}' https://identity.msrv.saas.appdynamics.com/v2.0/oauth/token | grep -oP '(\"access_token\"\:\s\")\K(.*?)(?=\"\,\s\")')
  curl -L -O -H "Authorization: Bearer ${TOKEN}" ${DOWNLOAD_PATH}
  echo "file downloaded"
  chmod +x ./$FILENAME
  ./$FILENAME -q -varfile ~/response.varfile
else
  echo "File found! Using existing version '$VERSION'"
fi
echo "Setting correct permissions"
chown -R nobody:users /config

echo "System Started"
