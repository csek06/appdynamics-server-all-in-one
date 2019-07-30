#!/bin/bash
cd /config
# Check for install - install if not found.
DA_DIR=/config/appdynamics/database-agent
if [ ! -f $DA_DIR/db-agent.jar ]; then
	#Check the latest version on appdynamics
	curl -s -L -o tmpout.json "https://download.appdynamics.com/download/downloadfile/?version=&apm=db&os=linux&platform_admin_os=&events=&eum="
	DA_VERSION=$(grep -oP '(?:filename\"\:\"db-agent-\d+\.\d+\.\d+\.\d+\.zip[\s\S]+?(?=version))(?:version\"\:\")\K(.*?)(?=\"\,)' tmpout.json)
	DOWNLOAD_PATH=$(grep -oP '(?:filename\"\:\"db-agent-\d+\.\d+\.\d+\.\d+\.zip[\s\S]+?(?=http))\K(.*?)(?=\"\,)' tmpout.json)
	FILENAME=$(grep -oP '(?:filename\"\:\")\K(db-agent-\d+\.\d+\.\d+\.\d+\.zip)(?=\"\,)' tmpout.json)
	echo "Latest version on appdynamics is" $DA_VERSION
	echo "DOWNLOAD_PATH: $DOWNLOAD_PATH"
	echo "FILENAME: $FILENAME"
	rm -f tmpout.json

	# check if user downloaded latest DA  binary
	if [ -f /config/$FILENAME ]; then
		echo "Found latest Database Agent '$FILENAME' in /config/ "
	else
		echo "Didn't find '$FILENAME' in /config/ - downloading"
		NEWTOKEN=$(curl -X POST -d '{"username": "'$AppdUser'","password": "'$AppdPass'","scopes": ["download"]}' https://identity.msrv.saas.appdynamics.com/v2.0/oauth/token | grep -oP '(\"access_token\"\:\s\")\K(.*?)(?=\"\,\s\")')
		curl -L -O -H "Authorization: Bearer ${NEWTOKEN}" ${DOWNLOAD_PATH}
		echo "file downloaded"
	fi
	echo "Unzipping: $FILENAME"
	mkdir -p $DA_DIR
	unzip -q /config/$FILENAME -d $DA_DIR
	echo "Unzip complete"
	rm /config/$FILENAME
else
	echo "Found existing database agent"
fi
