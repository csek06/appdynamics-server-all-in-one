#!/bin/bash

#Check the latest version on appdynamics
curl -s -L -o tmpout.json "https://download.appdynamics.com/download/downloadfile/?version=&apm=machine&os=linux&platform_admin_os=&events=&eum="
VERSION=$(grep -oP '(?:64-bit linux \(zip\)[\s\S]+?(?=version))(?:version\"\:\")\K(.*?)(?=\"\,)' tmpout.json)
DOWNLOAD_PATH=$(grep -oP '(?:64-bit linux \(zip\)[\s\S]+?(?=http))\K(.*?)(?=\"\,)' tmpout.json)
FILENAME=$(grep -oP '(?:\"filename\"\:\")\K(machineagent-bundle-64bit-linux-\d+\.\d+\.\d+\.\d+\.zip)(?=\"\,\"s3)' tmpout.json)
echo "Latest version on appdynamics is" $VERSION
echo "DOWNLOAD_PATH: $DOWNLOAD_PATH"
echo "FILENAME: $FILENAME"
rm -f tmpout.json

# Check for install - install if not found.
if [ ! -f /config/appdynamics/machine-agent/bin/machine-agent ]; then
	# check if user downloaded latest EUM server binary
	if [ -f /config/$FILENAME ]; then
		echo "Found latest Machine Agent '$FILENAME' in /config/ "
	else
		echo "Didn't find '$FILENAME' in /config/ - downloading"
		NEWTOKEN=$(curl -X POST -d '{"username": "'$AppdUser'","password": "'$AppdPass'","scopes": ["download"]}' https://identity.msrv.saas.appdynamics.com/v2.0/oauth/token | grep -oP '(\"access_token\"\:\s\")\K(.*?)(?=\"\,\s\")')
		curl -L -O -H "Authorization: Bearer ${NEWTOKEN}" ${DOWNLOAD_PATH}
		echo "file downloaded"
	fi
	echo "Unzipping: $FILENAME"
	unzip -q -d /config/appdynamics/machine-agent/ /config/$FILENAME
	echo "Unzip complete"
	rm /config/$FILENAME
else
	echo "Found existing machine agent"
fi