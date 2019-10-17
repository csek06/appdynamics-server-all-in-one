#!/bin/bash

# check if EUM Server is installed
if [ -f $APPD_INSTALL_DIR/appdynamics/EUM/eum-processor/bin/eum.sh ]; then
	INSTALLED_VERSION=$(grep -oP '(Monitoring\s)\K(.*?)(?=$)' $APPD_INSTALL_DIR/appdynamics/EUM/.install4j/response.varfile)
	echo "EUM Server: $INSTALLED_VERSION is installed"
	# check for upgrade <code to be inserted>, however upgrade path needs to be followed EC > ES > EUM > Controller
else
	# Check latest EUM server version on AppDynamics
	cd $APPD_INSTALL_DIR
	echo "Checking EUM server version"
	curl -s -L -o tmpout.json "https://download.appdynamics.com/download/downloadfile/?version=&apm=&os=linux&platform_admin_os=&events=&eum=linux"
	EUMDOWNLOAD_PATH=$(grep -oP '(?:filename\"\:\"euem-64bit-linux-\d+\.\d+\.\d+\.\d+\.sh[\s\S]+?(?=http))\K(.*?)(?=\"\,)' tmpout.json)
	EUMFILENAME=$(grep -oP '(?:filename\"\:\")\K(euem-64bit-linux-\d+\.\d+\.\d+\.\d+\.sh)(?=\"\,)' tmpout.json)
	rm -f tmpout.json
	# check if user downloaded latest EUM server binary
	if [ -f $APPD_INSTALL_DIR/$EUMFILENAME ]; then
		echo "Found latest EUM Server '$EUMFILENAME' in '$APPD_INSTALL_DIR' "
	else
		echo "Didn't find '$EUMFILENAME' in '$APPD_INSTALL_DIR' - downloading"
		NEWTOKEN=$(curl -s -X POST -d '{"username": "'$AppdUser'","password": "'$AppdPass'","scopes": ["download"]}' https://identity.msrv.saas.appdynamics.com/v2.0/oauth/token | grep -oP '(\"access_token\"\:\s\")\K(.*?)(?=\"\,\s\")')
		curl -L -O -H "Authorization: Bearer ${NEWTOKEN}" ${EUMDOWNLOAD_PATH}
		echo "file downloaded"
	fi
	chmod +x ./$EUMFILENAME

	echo "Installing EUM server"
	VARFILE=$APPD_SCRIPTS_DIR/install-scripts/response-eum.varfile
	if [ -f "$VARFILE" ];then 
		if [ -z $EVENTS_SERVICE_HOST ]; then 
			if [ -z $CONTROLLER_HOST ]; then
				EVENTS_SERVICE_HOST=localhost
			else
				EVENTS_SERVICE_HOST=$CONTROLLER_HOST
			fi
		fi
		if [ -z $EUM_SIZE ]; then
			EUM_SIZE=demo
		fi
		appdserver="eventsService.host=${EVENTS_SERVICE_HOST}"
		SYS_INSTALL_DIR="sys.installationDir=${APPD_INSTALL_DIR}/appdynamics/EUM"
		MYSQL_DATA_DIR="mysql.dataDir=${APPD_INSTALL_DIR}/appdynamics/EUM/data"
		echo "setting eum size '$EUM_SIZE' in '$VARFILE'"
		sed -i s/euem.InstallationMode=.*/euem.InstallationMode=$EUM_SIZE/ $VARFILE
		echo "setting '$MYSQL_DATA_DIR' in '$VARFILE'"
		sed -i s#mysql\.dataDir=.*#$MYSQL_DATA_DIR# $VARFILE
		echo "setting '$SYS_INSTALL_DIR' in '$VARFILE'"
		sed -i s#sys\.installationDir=.*#$SYS_INSTALL_DIR# $VARFILE
		echo "setting '$appdserver' in '$VARFILE'"
		sed -i s/eventsService.host=.*/$appdserver/ $VARFILE
		ES_EUM_KEY=$(curl -s --user admin@customer1:appd http://$CONTROLLER_HOST:$CONTROLLER_PORT/controller/rest/configuration?name=appdynamics.es.eum.key | grep -oP '(value\>)\K(.*?)(?=\<\/value)')
		echo "setting '$ES_EUM_KEY' in '$VARFILE'"
		sed -i s/eventsService.APIKey=.*/eventsService.APIKey=$ES_EUM_KEY/ $VARFILE
		if [ -z $ES_EUM_KEY ]; then
			echo "Couldn't connect to controller and obtain EUM Key - not installing EUM"
		else
			./$EUMFILENAME -q -varfile $VARFILE
			# assuming install went fine
			# let the user cleanup binaries
			# rm -f ./$EUMFILENAME
			EUM_POST_CONF_FILE=$APPD_SCRIPTS_DIR/install-scripts/post-install-EUM-Config.sh
			if [ -f "$EUM_POST_CONF_FILE" ]; then
				chmod +x $EUM_POST_CONF_FILE
				. $EUM_POST_CONF_FILE
			else
				echo "EUM Server post-config file not found here - $EUM_POST_CONF_FILE"
			fi
		fi
	else
		echo "Couldn't find $VARFILE"
	fi
 fi
