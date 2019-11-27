#!/bin/bash

# Use manual version or latest available from AppDynamics
cd $APPD_INSTALL_DIR
SYN_DIR=$APPD_INSTALL_DIR/appdynamics/synthetic-server
if [ -z $SYN_VERSION ]; then
	SYN_VERSION=latest
fi
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
	FILENAME=$(grep -oP '(?:results.*?)(?:filename\"\:\")\K(appdynamics-synthetic-server-\d+\.\d+\.\d+\.\d+\.zip)(?=\"\,)' tmpout.json)
	echo "Latest version on appdynamics is" $SYN_VERSION
fi
rm -f tmpout.json

# check if synthetic server is installed
if [ -f $SYN_DIR/inputs.groovy ]; then
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
	
	cd $SYN_DIR
	
	SYN_INSTALLER="unix/deploy.sh"
	if [ -f $SYN_INSTALLER ]; then
		# Setup EUM mysql db
		MYSQL_FILE=$APPD_INSTALL_DIR/appdynamics/EUM/mysql/bin/mysql
		if [ -f "$MYSQL_FILE" ]; then
			echo "Updating mysql to accomodate synthetic server"
			SOCK_FILE=$APPD_INSTALL_DIR/appdynamics/EUM/mysql/mysql.sock
			if [ -f $SOCK_FILE.lock ]; then
				echo "attempting grant all priveleges for root user for synthetic server host"
				$MYSQL_FILE -u root --password="appd" --socket $SOCK_FILE -e "GRANT ALL PRIVILEGES ON eum_db.* TO 'root'@'$HOSTNAME';"
				echo "attempting grant all priveleges for eum user for synthetic server host"
				$MYSQL_FILE -u root --password="appd" --socket $SOCK_FILE -e "GRANT ALL PRIVILEGES ON eum_db.* TO 'eum_user'@'$HOSTNAME';"
				echo "attempting set password for root for synthetic server host"
				$MYSQL_FILE -u root --password="appd" --socket $SOCK_FILE -e "SET PASSWORD FOR 'root'@'$HOSTNAME' = PASSWORD('appd');"
				echo "attempting show grants for eum user for synthetic server host"
				$MYSQL_FILE -u root --password="appd" --socket $SOCK_FILE -e "show grants for eum_user@$HOSTNAME;"
				echo "attempting show grants for root user for synthetic server host"
				$MYSQL_FILE -u root --password="appd" --socket $SOCK_FILE -e "show grants for root@$HOSTNAME;"
				
				# Setup groovy inputs
				GROOVY_FILE=$SYN_DIR/inputs.groovy
				cp $SYN_DIR/inputs.groovy.sample $GROOVY_FILE
				if [ -f "$GROOVY_FILE" ]; then
					# setting the proper groovy inputs
					db_host='db_host = "'"$EUM_HOST"'"'
					db_port='db_port = "3388"'
					db_root_password='db_root_pwd = "appd"'
					db_username='db_username = "eum_user"'
					db_password='db_user_pwd = "appd"'
					collector_host='collector_host = "'"$EUM_HOST"'"'
					collector_port='collector_port = "7001"'
					key_store_password='key_store_password = "appd"'
					localFileStoreRootPath='localFileStoreRootPath = "'"$SYN_DIR"'/data"'
					controller_host='controller_host = "http://'"$CONTROLLER_HOST"'"'
					controller_port='controller_port = "8090"'
					controller_username='controller_username = "admin"'
					controller_password='controller_password = "appd"'
					
					echo "Setting $db_host in $GROOVY_FILE"
					echo "Setting $db_port in $GROOVY_FILE"
					echo "Setting $db_root_password in $GROOVY_FILE"
					echo "Setting $db_username in $GROOVY_FILE"
					echo "Setting $db_password in $GROOVY_FILE"
					echo "Setting $collector_host in $GROOVY_FILE"
					echo "Setting $collector_port in $GROOVY_FILE"
					echo "Setting $key_store_password in $GROOVY_FILE"
					echo "Setting $localFileStoreRootPath in $GROOVY_FILE"
					echo "Setting $controller_host in $GROOVY_FILE"
					echo "Setting $controller_port in $GROOVY_FILE"
					echo "Setting $controller_username in $GROOVY_FILE"
					echo "Setting $controller_password in $GROOVY_FILE"
										
					sed -i s#'db_host = "'.*'"'#"$db_host"# $GROOVY_FILE
					sed -i s#'db_port = "'.*'"'#"$db_port"# $GROOVY_FILE
					sed -i s#'db_root_pwd = "'.*'"'#"$db_root_password"# $GROOVY_FILE
					sed -i s#'db_username = "'.*'"'#"$db_username"# $GROOVY_FILE
					sed -i s#'db_user_pwd = "'.*'"'#"$db_password"# $GROOVY_FILE
					sed -i s#'collector_host = "'.*'"'#"$collector_host"# $GROOVY_FILE
					sed -i s#'collector_port = "'.*'"'#"$collector_port"# $GROOVY_FILE
					sed -i s#'key_store_password = "'.*'"'#"$key_store_password"# $GROOVY_FILE
					sed -i s#'localFileStoreRootPath = "'.*'"'#"$localFileStoreRootPath"# $GROOVY_FILE
					sed -i s#'controller_host = "'.*'"'#"$controller_host"# $GROOVY_FILE
					sed -i s#'controller_port = "'.*'"'#"$controller_port"# $GROOVY_FILE
					sed -i s#'controller_username = "'.*'"'#"$controller_username"# $GROOVY_FILE
					sed -i s#'controller_password = "'.*'"'#"$controller_password"# $GROOVY_FILE
					
					echo "Ensuring installer: $SYN_DIR/$SYN_INSTALLER is executable"
					chmod +x $SYN_INSTALLER
					. $SYN_INSTALLER install
					# assuming install went fine
					# let the user cleanup binaries
					# rm -f ./$FILENAME
					SYN_POST_CONF_FILE=$APPD_SCRIPTS_DIR/install-scripts/post-install-SYN-Config.sh
					if [ -f "$SYN_POST_CONF_FILE" ]; then
						chmod +x $SYN_POST_CONF_FILE
						. $SYN_POST_CONF_FILE
					else
						echo "Synthetic Server post-config file not found here - $SYN_POST_CONF_FILE"
						exit 1
					fi
				else
					echo "GROOVY_FILE: $GROOVY_FILE doesn't exist - not installing Synthetic Server"
					exit 1
				fi
			else
				echo "mysql sock file: $SOCK_FILE not found - is EUM running?"
				exit 1
			fi
		else
			echo "mysql file: $MYSQL_FILE not found - not installing Synthetic Server"
			exit 1
		fi
	fi
fi