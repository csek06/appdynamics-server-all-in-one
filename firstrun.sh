#!/bin/bash

#Get docker env timezone and set system timezone
echo "setting the correct local time"
echo $TZ > /etc/timezone
export DEBCONF_NONINTERACTIVE_SEEN=true DEBIAN_FRONTEND=noninteractive
dpkg-reconfigure tzdata

# this will overwrite similar named files in container 
# if there is an issue with a script than delete the file and restart container.
if [ -d "/config/your-platform-install" ];then
	cp -rf /config/your-platform-install/install-scripts /your-platform-install/
	cp -rf /config/your-platform-install/startup-scripts /your-platform-install/
fi

# Copy install scripts to volume for later update/reconfigure
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