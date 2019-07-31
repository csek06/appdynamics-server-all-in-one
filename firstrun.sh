#!/bin/bash

#Get docker env timezone and set system timezone
echo "setting the correct local time"
echo $TZ > /etc/timezone
export DEBCONF_NONINTERACTIVE_SEEN=true DEBIAN_FRONTEND=noninteractive
dpkg-reconfigure tzdata

# Check for Install Scenario Variable
if [ -z $SCENARIO ]; then
	SCENARIO=ECCONT
fi

if [[ $SCENARIO = *EC* ]]; then
	echo "Container will use EC";
	EC=true
fi
if [[ $SCENARIO = *ES* ]]; then
	echo "Container will use ES";
	ES=true
fi
if [[ $SCENARIO = *CONT* ]]; then
	echo "Container will use Controller";
	CONT=true
fi
if [[ $SCENARIO = *EUM* ]]; then
	echo "Container will use EUM";
	EUM=true
fi
if [[ $SCENARIO = *AA* ]]; then
	echo "Container will use Analytics Agent";
	AA=true
	# must also have MA
	if [[ ! $SCENARIO = *MA* ]]; then
		echo "Adding MA to SCENARIO variable";
		SCENARIO="$SCENARIO MA"
	fi
fi
if [[ $SCENARIO = *MA* ]]; then
	echo "Container will use Machine Agent";
	MA=true
fi
if [[ $SCENARIO = *DA* ]]; then
	echo "Container will use Database Agent";
	DA=true
fi
if [[ $SCENARIO = *GEO* ]]; then
	echo "Container will use Custom Geo Server";
	GEO=true
fi

# this will overwrite similar named files in container 
# if there is an issue with a script than delete the file in your volume and restart container.
if [ -d "/config/your-platform-install/install-scripts" ];then
	BACKUP_CUSTOM=/config/your-platform-install/backup-custom-install-scripts/
	mkdir -p $BACKUP_CUSTOM
	# Checking for custom install scripts
	DIR=/your-platform-install/defaults/install-scripts/
	cd $DIR
	for filename in $(ls); do
		FILE_CHECK=/config$DIR$filename
		if [ -f $FILE_CHECK ]; then
			echo "Manual install file found $filename - overwriting default"
			cp -rf $FILE_CHECK /your-platform-install/install-scripts/
		else
			echo "Custom install file not found $filename - using default"
			cp -rf /your-platform-install/defaults/install-scripts/$filename /your-platform-install/install-scripts/
		fi
	done
	mv -f /config$DIR $BACKUP_CUSTOM
else
	cp -rf /your-platform-install/defaults/install-scripts /your-platform-install/
fi

# this will overwrite similar named files in container 
# if there is an issue with a script than delete the file in your volume and restart container.
if [ -d "/config/your-platform-install/startup-scripts" ];then
	BACKUP_CUSTOM=/config/your-platform-install/backup-custom-startup-scripts/
	mkdir -p $BACKUP_CUSTOM
	# Checking for custom startup scripts
	DIR=/your-platform-install/defaults/startup-scripts/
	cd $DIR
	for filename in $(ls); do
		FILE_CHECK=/config$DIR$filename
		if [ -f $FILE_CHECK ]; then
			echo "Manual startup file found $filename - overwriting default"
			cp -rf $FILE_CHECK /your-platform-install/startup-scripts/
		else
			echo "Custom startup file not found $filename - using default"
			cp -rf /your-platform-install/defaults/startup-scripts/$filename /your-platform-install/startup-scripts/
		fi
	done
	mv -f /config$DIR $BACKUP_CUSTOM
else
	cp -rf /your-platform-install/defaults/startup-scripts /your-platform-install/
fi

# Copy install/startup scripts to volume for later update/reconfigure
# cp -rf /your-platform-install/ /config/

if [ "$EC" = "true" ]; then
	EC_INSTALL_UPGRADE_FILE=/your-platform-install/install-scripts/install-upgrade-EC.sh
	if [ -f "$EC_INSTALL_UPGRADE_FILE" ]; then
		chmod +x $EC_INSTALL_UPGRADE_FILE
		bash $EC_INSTALL_UPGRADE_FILE
	else
		echo "EC install file not found here - $EC_INSTALL_UPGRADE_FILE"
	fi
fi

# Ensure the EC is started to allow the install of other services
if [ "$EC" = "true" ]; then
	EC_START_FILE=/your-platform-install/startup-scripts/start-EC.sh
	if [ -f "$EC_START_FILE" ]; then
		chmod +x $EC_START_FILE
		bash $EC_START_FILE
	else
		echo "EC Server startup file not found here - $EC_START_FILE"
	fi
fi

if [ "$CONT" = "true" ]; then
	CONT_INSTALL_UPGRADE_FILE=/your-platform-install/install-scripts/install-upgrade-Controller.sh
	if [ -f "$CONT_INSTALL_UPGRADE_FILE" ]; then
		chmod +x $CONT_INSTALL_UPGRADE_FILE
		bash $CONT_INSTALL_UPGRADE_FILE
	else
		echo "Controller install file not found here - $CONT_INSTALL_UPGRADE_FILE"
	fi
fi

if [ "$ES" = "true" ]; then
	ES_INSTALL_UPGRADE_FILE=/your-platform-install/install-scripts/install-upgrade-ES.sh
	if [ -f "$ES_INSTALL_UPGRADE_FILE" ]; then
		chmod +x $ES_INSTALL_UPGRADE_FILE
		bash $ES_INSTALL_UPGRADE_FILE
	else
		echo "Events Services install file not found here - $ES_INSTALL_UPGRADE_FILE"
	fi
fi

if [ "$EUM" = "true" ]; then
	EUM_INSTALL_UPGRADE_FILE=/your-platform-install/install-scripts/install-upgrade-EUM.sh
	if [ -f "$EUM_INSTALL_UPGRADE_FILE" ]; then
		chmod +x $EUM_INSTALL_UPGRADE_FILE
		bash $EUM_INSTALL_UPGRADE_FILE
	else
		echo "EUM Server install file not found here - $EUM_INSTALL_UPGRADE_FILE"
	fi
fi

if [ "$MA" = "true" ]; then
	MA_INSTALL_UPGRADE_FILE=/your-platform-install/install-scripts/install-upgrade-MA.sh
	if [ -f "$MA_INSTALL_UPGRADE_FILE" ]; then
		chmod +x $MA_INSTALL_UPGRADE_FILE
		bash $MA_INSTALL_UPGRADE_FILE
		# adding analytics agent if applicable
		if [ "$AA" = "true" ]; then
			AA_INSTALL_UPGRADE_FILE=/your-platform-install/install-scripts/install-upgrade-AA.sh
			if [ -f "$AA_INSTALL_UPGRADE_FILE" ]; then
				chmod +x $AA_INSTALL_UPGRADE_FILE
				bash $AA_INSTALL_UPGRADE_FILE
			else
				echo "Analytics Agent install file not found here - $AA_INSTALL_UPGRADE_FILE"
			fi
		fi
	else
		echo "Machine Agent install file not found here - $MA_INSTALL_UPGRADE_FILE"
	fi
fi

if [ "$DA" = "true" ]; then
	DA_INSTALL_UPGRADE_FILE=/your-platform-install/install-scripts/install-upgrade-DA.sh
	if [ -f "$DA_INSTALL_UPGRADE_FILE" ]; then
		chmod +x $DA_INSTALL_UPGRADE_FILE
		bash $DA_INSTALL_UPGRADE_FILE
	else
		echo "Database Agent install file not found here - $DA_INSTALL_UPGRADE_FILE"
	fi
fi

if [ "$GEO" = "true" ]; then
	GEO_INSTALL_UPGRADE_FILE=/your-platform-install/install-scripts/install-upgrade-GEO.sh
	if [ -f "$GEO_INSTALL_UPGRADE_FILE" ]; then
		chmod +x $GEO_INSTALL_UPGRADE_FILE
		bash $GEO_INSTALL_UPGRADE_FILE
	else
		echo "Custom Geo Server install file not found here - $GEO_INSTALL_UPGRADE_FILE"
	fi
fi


echo "Setting correct permissions"
chown -R nobody:users /config

# Start the AppDynamics Services
echo "Starting AppDynamics Services"

if [ "$CONT" = "true" ]; then
	CONT_START_FILE=/your-platform-install/startup-scripts/start-Controller.sh
	if [ -f "$CONT_START_FILE" ]; then
		chmod +x $CONT_START_FILE
		bash $CONT_START_FILE
	else
		echo "EC Server startup file not found here - $CONT_START_FILE"
	fi
fi

if [ "$ES" = "true" ]; then
	ES_START_FILE=/your-platform-install/startup-scripts/start-ES.sh
	if [ -f "$ES_START_FILE" ]; then
		chmod +x $ES_START_FILE
		bash $ES_START_FILE
	else
		echo "ES Server startup file not found here - $ES_START_FILE"
	fi
fi

if [ "$EUM" = "true" ]; then
	EUM_START_FILE=/your-platform-install/startup-scripts/start-EUM.sh
	if [ -f "$EUM_START_FILE" ]; then
		chmod +x $EUM_START_FILE
		bash $EUM_START_FILE
		# Activate new EUM license file
		EUM_ACTIVATE_LICENSE_FILE=/your-platform-install/startup-scripts/activate-eum-license.sh
		if [ -f "$EUM_ACTIVATE_LICENSE_FILE" ]; then
			chmod +x $EUM_ACTIVATE_LICENSE_FILE
			bash $EUM_ACTIVATE_LICENSE_FILE
		else
			echo "EUM activate license file not found here - $EUM_ACTIVATE_LICENSE_FILE"
		fi
	else
		echo "EUM Server startup file not found here - $EUM_START_FILE"
	fi
fi

if [ "$MA" = "true" ]; then
	MA_START_FILE=/your-platform-install/startup-scripts/start-MA.sh
	if [ -f "$MA_START_FILE" ]; then
		chmod +x $MA_START_FILE
		bash $MA_START_FILE
	else
		echo "Machine Agent startup file not found here - $MA_START_FILE"
	fi
fi

if [ "$DA" = "true" ]; then
	DA_START_FILE=/your-platform-install/startup-scripts/start-DA.sh
	if [ -f "$DA_START_FILE" ]; then
		chmod +x $DA_START_FILE
		bash $DA_START_FILE
	else
		echo "Database Agent startup file not found here - $DA_START_FILE"
	fi
fi

if [ "$CONT" = "true" ]; then
	if [ -f /config/license.lic ]; then
		mv -f /config/license.lic /config/appdynamics/controller/
	fi
fi

echo "System Started"