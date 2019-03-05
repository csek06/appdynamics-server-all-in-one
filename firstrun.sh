#!/bin/bash

#Get docker env timezone and set system timezone
echo "setting the correct local time"
echo $TZ > /etc/timezone
export DEBCONF_NONINTERACTIVE_SEEN=true DEBIAN_FRONTEND=noninteractive
dpkg-reconfigure tzdata

# Check for Install Scenario Variable
if [ -z $SCENARIO ]; then
	SCENARIO=ECESCONTEUM
fi

if [[ $SCENARIO = *EC* ]]; then
	echo "Platform will use EC";
fi
if [[ $SCENARIO = *ES* ]]; then
	echo "Platform will use ES";
fi
if [[ $SCENARIO = *CONT* ]]; then
	echo "Platform will use Controller";
fi
if [[ $SCENARIO = *EUM* ]]; then
	echo "Platform will use EUM";
fi


case $SCENARIO in 
	ALL)
		echo "Platform will use everything";;
	EC)
		echo "Platform will use EC Only";;
	ES)
		echo "Platform will use ES Only";;
	CONT)
		echo "Platform will use CONT Only";;
	EUM)
		echo "Platform will use EUM Only";;
esac

# this will overwrite similar named files in container 
# if there is an issue with a script than delete the file and restart container.
if [ -d "/config/your-platform-install/install-scripts" ];then
	# Checking for custom install scripts
	DIR=/your-platform-install/defaults/install-scripts/
	cd $DIR
	for filename in $(ls); do
		FILE_CHECK=/config/your-platform-install/install-scripts/$filename
		if [ -f $FILE_CHECK ]; then
			echo "Manual install file found $filename - overwriting default"
			cp -rf $FILE_CHECK /your-platform-install/install-scripts/
		else
			echo "Custom install file not found $filename - using default"
			cp -rf /your-platform-install/defaults/install-scripts/$filename /your-platform-install/install-scripts/
		fi
	done
else
	cp -rf /your-platform-install/defaults/install-scripts /your-platform-install/
fi

# this will overwrite similar named files in container 
# if there is an issue with a script than delete the file and restart container.
if [ -d "/config/your-platform-install/startup-scripts" ];then
	# Checking for custom startup scripts
	DIR=/your-platform-install/defaults/startup-scripts/
	cd $DIR
	for filename in $(ls); do
		FILE_CHECK=/config/your-platform-install/startup-scripts/$filename
		if [ -f $FILE_CHECK ]; then
			echo "Manual startup file found $filename - overwriting default"
			cp -rf $FILE_CHECK /your-platform-install/startup-scripts/
		else
			echo "Custom startup file not found $filename - using default"
			cp -rf /your-platform-install/defaults/startup-scripts/$filename /your-platform-install/startup-scripts/
		fi
	done
else
	cp -rf /your-platform-install/defaults/startup-scripts /your-platform-install/
fi

# Copy install/startup scripts to volume for later update/reconfigure
cp -rf /your-platform-install/ /config/

EC_INSTALL_UPGRADE_FILE=/your-platform-install/install-scripts/install-upgrade-EC.sh
if [ -f "$EC_INSTALL_UPGRADE_FILE" ]; then
	chmod +x $EC_INSTALL_UPGRADE_FILE
	sh $EC_INSTALL_UPGRADE_FILE
else
	echo "EC install file not found here - $EC_INSTALL_UPGRADE_FILE"
fi

CONT_INSTALL_UPGRADE_FILE=/your-platform-install/install-scripts/install-upgrade-Controller.sh
if [ -f "$CONT_INSTALL_UPGRADE_FILE" ]; then
	chmod +x $CONT_INSTALL_UPGRADE_FILE
	sh $CONT_INSTALL_UPGRADE_FILE
else
	echo "Controller install file not found here - $CONT_INSTALL_UPGRADE_FILE"
fi

ES_INSTALL_UPGRADE_FILE=/your-platform-install/install-scripts/install-upgrade-ES.sh
if [ -f "$ES_INSTALL_UPGRADE_FILE" ]; then
	chmod +x $ES_INSTALL_UPGRADE_FILE
	sh $ES_INSTALL_UPGRADE_FILE
else
	echo "Events Services install file not found here - $ES_INSTALL_UPGRADE_FILE"
fi

EUM_INSTALL_UPGRADE_FILE=/your-platform-install/install-scripts/install-upgrade-EUM.sh
if [ -f "$EUM_INSTALL_UPGRADE_FILE" ]; then
	chmod +x $EUM_INSTALL_UPGRADE_FILE
	sh $EUM_INSTALL_UPGRADE_FILE
else
	echo "EUM Server install file not found here - $EUM_INSTALL_UPGRADE_FILE"
fi


echo "Setting correct permissions"
chown -R nobody:users /config

# Start the AppDynamics Services
echo "Starting AppDynamics Services"


EC_START_FILE=/your-platform-install/startup-scripts/start-EC.sh
if [ -f "$EC_START_FILE" ]; then
	chmod +x $EC_START_FILE
	sh $EC_START_FILE
else
	echo "EC Server startup file not found here - $EC_START_FILE"
fi

CONT_START_FILE=/your-platform-install/startup-scripts/start-Controller.sh
if [ -f "$CONT_START_FILE" ]; then
	chmod +x $CONT_START_FILE
	sh $CONT_START_FILE
else
	echo "EC Server startup file not found here - $CONT_START_FILE"
fi

ES_START_FILE=/your-platform-install/startup-scripts/start-ES.sh
if [ -f "$ES_START_FILE" ]; then
	chmod +x $ES_START_FILE
	sh $ES_START_FILE
else
	echo "ES Server startup file not found here - $ES_START_FILE"
fi

EUM_START_FILE=/your-platform-install/startup-scripts/start-EUM.sh
if [ -f "$EUM_START_FILE" ]; then
	chmod +x $EUM_START_FILE
	sh $EUM_START_FILE
else
	echo "EUM Server startup file not found here - $EUM_START_FILE"
fi

# Activate new EUM license file
EUM_ACTIVATE_LICENSE_FILE=/your-platform-install/startup-scripts/activate-eum-license.sh
if [ -f "$EUM_ACTIVATE_LICENSE_FILE" ]; then
	chmod +x $EUM_ACTIVATE_LICENSE_FILE
	sh $EUM_ACTIVATE_LICENSE_FILE
else
	echo "EUM activate license file not found here - $EUM_ACTIVATE_LICENSE_FILE"
fi

echo "System Started"
