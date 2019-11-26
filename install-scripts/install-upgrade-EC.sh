#!/bin/bash

# Use manual version or latest available from AppDynamics
cd $APPD_INSTALL_DIR
if [ ! "$EC_VERSION" = "latest" ]; then
	echo "Manual version override:" $EC_VERSION
	#Check for valid version on appdynamics
	curl -s -L -o tmpout.json "https://download.appdynamics.com/download/downloadfile/?version=$EC_VERSION&apm=&os=linux&platform_admin_os=linux&events=&eum="
	EC_VERSION=$(grep -oP '(?:filename\"\:\"platform-setup-x64-linux-\d+\.\d+\.\d+\.\d+\.sh[\s\S]+?(?=version))(?:version\"\:\")\K(.*?)(?=\"\,)' tmpout.json)
	DOWNLOAD_PATH=$(grep -oP '(?:filename\"\:\"platform-setup-x64-linux-\d+\.\d+\.\d+\.\d+\.sh[\s\S]+?(?=http))\K(.*?)(?=\"\,)' tmpout.json)
	FILENAME=$(grep -oP '(?:filename\"\:\")\K(platform-setup-x64-linux-\d+\.\d+\.\d+\.\d+\.sh)(?=\"\,)' tmpout.json)
	echo "Filename expected: $FILENAME"
else
	#Check the latest version on appdynamics
	curl -s -L -o tmpout.json "https://download.appdynamics.com/download/downloadfile/?version=&apm=&os=linux&platform_admin_os=linux&events=&eum="
	EC_VERSION=$(grep -oP '(?:filename\"\:\"platform-setup-x64-linux-\d+\.\d+\.\d+\.\d+\.sh[\s\S]+?(?=version))(?:version\"\:\")\K(.*?)(?=\"\,)' tmpout.json)
	DOWNLOAD_PATH=$(grep -oP '(?:filename\"\:\"platform-setup-x64-linux-\d+\.\d+\.\d+\.\d+\.sh[\s\S]+?(?=http))\K(.*?)(?=\"\,)' tmpout.json)
	FILENAME=$(grep -oP '(?:filename\"\:\")\K(platform-setup-x64-linux-\d+\.\d+\.\d+\.\d+\.sh)(?=\"\,)' tmpout.json)
	echo "Latest version on appdynamics is" $EC_VERSION
fi
rm -f tmpout.json

# check if enterprise console is installed
if [ -f $APPD_INSTALL_DIR/appdynamics/enterprise-console/platform-admin/bin/platform-admin.sh ]; then
	# check if enterprise console is out of date compared to $EC_VERSION
	cd $APPD_INSTALL_DIR/appdynamics/enterprise-console/platform-admin/archives/platform-configuration/
	EC_INSTALLED_VERSION=$(grep -oP '(^platformVersion\:\s\")\K(.*?)(?=\"$)' * | tr -d '\0')
	echo "Enterprise Console: $EC_INSTALLED_VERSION is installed"
	if [ "$EC_VERSION" != "$EC_INSTALLED_VERSION" ]; then
		echo "Version mismatch between found and requested/latest"
		echo "Found Installed EC Version: $EC_INSTALLED_VERSION , but requesting version $EC_VERSION"
		echo "Upgrade needed, however this feature is not yet implemented!!!"
	else
		echo "You have the most up to date version: $EC_VERSION"
	fi
else
	# check if user didn't downloaded latest Enterprise Console binary
	if [ ! -f $APPD_INSTALL_DIR/$FILENAME ]; then
		echo "Didn't find '$FILENAME' in '$APPD_INSTALL_DIR' - downloading instead"
		echo "Downloading AppDynamics Enterprise Console version '$EC_VERSION'"
		TOKEN=$(curl -X POST -d '{"username": "'$AppdUser'","password": "'$AppdPass'","scopes": ["download"]}' https://identity.msrv.saas.appdynamics.com/v2.0/oauth/token | grep -oP '(\"access_token\"\:\s\")\K(.*?)(?=\"\,\s\")')
		curl -L -O -H "Authorization: Bearer ${TOKEN}" ${DOWNLOAD_PATH}
		echo "file downloaded"
	else
		echo "Found latest Enterprise Console '$FILENAME' in '$APPD_INSTALL_DIR' "
	fi
	#Configure Appd for IP address given as environment variable
	VARFILE=$APPD_SCRIPTS_DIR/install-scripts/response.varfile
	if [ -f "$VARFILE" ];then 
		if [ -z $CONTROLLER_HOST ]; then
			CONTROLLER_HOST=$HOSTNAME
		fi
		if [ -z $CONTROLLER_USE_HTTPS ]; then
			CONTROLLER_USE_HTTPS=false
		fi
		appdserver="serverHostName=${CONTROLLER_HOST}"
		MYSQL_DATA_DIR="platformAdmin.dataDir=${APPD_INSTALL_DIR}/appdynamics/enterprise-console/mysql/data"
		SYS_INSTALL_DIR="sys.installationDir=${APPD_INSTALL_DIR}/appdynamics/enterprise-console/"
		CONTROLLER_USE_SSL="platformAdmin.useHttps\$Boolean=$CONTROLLER_USE_HTTPS"
		echo "setting '$appdserver' in '$VARFILE'"
		sed -i s/serverHostName=.*/$appdserver/ $VARFILE
		echo "setting '$MYSQL_DATA_DIR' in '$VARFILE'"
		sed -i s#platformAdmin\.dataDir=.*#$MYSQL_DATA_DIR# $VARFILE
		echo "setting '$SYS_INSTALL_DIR' in '$VARFILE'"
		sed -i s#sys\.installationDir=.*#$SYS_INSTALL_DIR# $VARFILE
		echo "setting '$CONTROLLER_USE_SSL' in '$VARFILE'"
		sed -i s#platform-admin\.useHttps.*#$CONTROLLER_USE_SSL# $VARFILE
		chmod +x ./$FILENAME
		echo "Installing Enterprise Console"
		./$FILENAME -q -varfile $VARFILE
		# assuming install went fine
		# let the user cleanup binaries
		# rm -f ./$FILENAME
	else
		echo "Couldn't find $VARFILE"
	fi
fi