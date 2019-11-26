#!/bin/bash

# Use manual version or latest available from AppDynamics
cd $APPD_INSTALL_DIR
SYN_DIR=$APPD_INSTALL_DIR/appdynamics/synthetic-server
if [ ! "$SYN_VERSION" = "latest" ]; then
	echo "Manual version override:" $SYN_VERSION
	#Check for valid version on appdynamics
	curl -s -L -o tmpout.json "https://download.appdynamics.com/download/downloadfile/?version=$SYN_VERISON&apm=&os=&platform_admin_os=&appdynamics_cluster_os=&events=&eum=synthetic-server"
	SYN_VERSION=$(grep -oP '(?:results.*?)(?:version\"\:\")\K(\d+\.\d+\.\d+\.\d+)(?=\"\,)' tmpout.json)
	DOWNLOAD_PATH=$(grep -oP '(?:results.*?)(?:download_path\"\:\")\K(https.*?appdynamics-synthetic-server-\d+\.\d+\.\d+\.\d+\.zip)(?=\"\,)' tmpout.json)
	FILENAME=$(grep -oP '(?:results.*?)(?:filename\"\:\")\K(appdynamics-synthetic-server-\d+\.\d+\.\d+\.\d+\.zip)(?=\"\,)' tmpout.json)
	echo "Filename expected: $FILENAME"
else
	#Check the latest version on appdynamics
	curl -s -L -o tmpout.json "https://download.appdynamics.com/download/downloadfile/?version=&apm=&os=&platform_admin_os=&appdynamics_cluster_os=&events=&eum=synthetic-server"
	SYN_VERSION=$(grep -oP '(?:results.*?)(?:version\"\:\")\K(\d+\.\d+\.\d+\.\d+)(?=\"\,)' tmpout.json)
	DOWNLOAD_PATH=$(grep -oP '(?:results.*?)(?:download_path\"\:\")\K(https.*?appdynamics-synthetic-server-\d+\.\d+\.\d+\.\d+\.zip)(?=\"\,)' tmpout.json)
	FILENAME=$(grep -oP '((?:results.*?)(?:filename\"\:\")\K(appdynamics-synthetic-server-\d+\.\d+\.\d+\.\d+\.zip)(?=\"\,)' tmpout.json)
	echo "Latest version on appdynamics is" $SYN_VERSION
fi
rm -f tmpout.json

# check if synthetic server is installed
if [ -f $SYN_DIR/deploy.sh ]; then
	# check if synthetic server is out of date compared to $SYN_VERSION
	#cd $APPD_INSTALL_DIR/appdynamics/enterprise-console/platform-admin/archives/platform-configuration/
	#SYN_INSTALLED_VERSION=$(grep -oP '(^platformVersion\:\s\")\K(.*?)(?=\"$)' * | tr -d '\0')
	echo "Synthetic Server: $SYN_INSTALLED_VERSION is installed"
	if [ "$SYN_VERSION" != "$SYN_INSTALLED_VERSION" ]; then
		echo "Version mismatch between found and requested/latest"
		echo "Found Installed Synthetic Server Version: $SYN_INSTALLED_VERSION , but requesting version $SYN_VERSION"
		echo "Upgrade needed, however this feature is not yet implemented!!!"
	else
		echo "You have the most up to date version: $SYN_VERSION"
	fi
else
	# check if user didn't downloaded latest Synthetic Server binary
	if [ ! -f $APPD_INSTALL_DIR/$FILENAME ]; then
		echo "Didn't find '$FILENAME' in '$APPD_INSTALL_DIR' - downloading instead"
		echo "Downloading AppDynamics Synthetic Server version '$SYN_VERSION'"
		TOKEN=$(curl -X POST -d '{"username": "'$AppdUser'","password": "'$AppdPass'","scopes": ["download"]}' https://identity.msrv.saas.appdynamics.com/v2.0/oauth/token | grep -oP '(\"access_token\"\:\s\")\K(.*?)(?=\"\,\s\")')
		curl -L -O -H "Authorization: Bearer ${TOKEN}" ${DOWNLOAD_PATH}
		echo "file downloaded"
	else
		echo "Found latest Synthetic Server '$FILENAME' in '$APPD_INSTALL_DIR' "
	fi
	
	echo "Unzipping: $FILENAME"
	mkdir -p $SYN_DIR
	unzip -q $APPD_INSTALL_DIR/$FILENAME -d $SYN_DIR
	echo "Unzip complete"
	echo "Installing Synthetic Server"
	SYN_INSTALLER=$SYN_DIR/deploy.sh
	if [ -f $SYN_INSTALLER ]; then
		chmod +x $SYN_INSTALLER
		./$SYN_INSTALLER install
	fi
	# assuming install went fine
	# let the user cleanup binaries
	# rm -f ./$FILENAME
fi