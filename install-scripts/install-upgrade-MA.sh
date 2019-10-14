#!/bin/bash
cd $APPD_INSTALL_DIR
# Check for install - install if not found.
MA_DIR=$APPD_INSTALL_DIR/appdynamics/machine-agent
if [ ! -f $MA_DIR/bin/machine-agent ]; then
	#Check the latest version on appdynamics
	curl -s -L -o tmpout.json "https://download.appdynamics.com/download/downloadfile/?version=&apm=machine&os=linux&platform_admin_os=&events=&eum="
	MA_VERSION=$(grep -oP '(?:64-bit linux \(zip\)[\s\S]+?(?=version))(?:version\"\:\")\K(.*?)(?=\"\,)' tmpout.json)
	DOWNLOAD_PATH=$(grep -oP '(?:64-bit linux \(zip\)[\s\S]+?(?=http))\K(.*?)(?=\"\,)' tmpout.json)
	FILENAME=$(grep -oP '(?:\"filename\"\:\")\K(machineagent-bundle-64bit-linux-\d+\.\d+\.\d+\.\d+\.zip)(?=\"\,\"s3)' tmpout.json)
	echo "Latest version on appdynamics is" $MA_VERSION
	echo "DOWNLOAD_PATH: $DOWNLOAD_PATH"
	echo "FILENAME: $FILENAME"
	rm -f tmpout.json

	# check if user downloaded latest EUM server binary
	if [ -f $APPD_INSTALL_DIR/$FILENAME ]; then
		echo "Found latest Machine Agent '$FILENAME' in '$APPD_INSTALL_DIR' "
	else
		echo "Didn't find '$FILENAME' in '$APPD_INSTALL_DIR' - downloading"
		NEWTOKEN=$(curl -X POST -d '{"username": "'$AppdUser'","password": "'$AppdPass'","scopes": ["download"]}' https://identity.msrv.saas.appdynamics.com/v2.0/oauth/token | grep -oP '(\"access_token\"\:\s\")\K(.*?)(?=\"\,\s\")')
		curl -L -O -H "Authorization: Bearer ${NEWTOKEN}" ${DOWNLOAD_PATH}
		echo "file downloaded"
	fi
	echo "Unzipping: $FILENAME"
	
	mkdir -p $MA_DIR
	unzip -q $APPD_INSTALL_DIR/$FILENAME -d $MA_DIR
	echo "Unzip complete"
	rm $APPD_INSTALL_DIR/$FILENAME
else
	echo "Found existing machine agent"
fi
