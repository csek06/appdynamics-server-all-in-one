#!/bin/bash

# Set location of FORM file based upon deployment type
if [ -d "/your-platform-install" ]; then
	# this must be a docker install
	FORM_FILE=/opt/appdynamics/your-platform.env
	APPD_SCRIPTS_DIR=/your-platform-install
else 
	if [ -d "$PWD/install-scripts" ]; then
		# this must be a standalone install
		APPD_SCRIPTS_DIR=$PWD
		FORM_FILE=$APPD_SCRIPTS_DIR/your-platform.env
	fi
fi

# no need for the below if using docker-compose
if [ ! "$COMPOSED" = "true" ]; then
	# Identify if a custom form file exists in known / local location
	if [ -f $FORM_FILE ]; then 
		# set the environment variables from file
		set -a; . $FORM_FILE; set +a
	else
		echo "Platform file does not exist here - $FORM_FILE"
		DEFAULT_FORM_FILE=$APPD_SCRIPTS_DIR/defaults/install-scripts/your-platform.env
		if [ ! -f $DEFAULT_FORM_FILE ]; then
			DEFAULT_FORM_FILE=$APPD_SCRIPTS_DIR/install-scripts/your-platform.env
		fi
		# copy form file to $APPD_SCRIPTS_DIR
		cp -f $DEFAULT_FORM_FILE $FORM_FILE
		chown nobody:users $FORM_FILE
		echo "Template platform file copied to '$APPD_SCRIPTS_DIR', please update and restart docker or rerun script"
		exit 1
	fi 

	# Install updates and necessary OS packages - not necessary for docker
	if [ "$RHEL_OR_CENTOS" = "true" ]; then
		echo "updating and installing packages"
		sudo yum update -y
		sudo yum install curl epel-release ibaio ncurses numactl tar tzdata unzip -y
		sudo yum install python-pip -y
		echo "updating firewall ports"
		sudo firewall-cmd --zone=public --add-port=9191/tcp --permanent
		sudo firewall-cmd --zone=public --add-port=8090/tcp --permanent
		sudo firewall-cmd --zone=public --add-port=8181/tcp --permanent
		sudo firewall-cmd --zone=public --add-port=7001/tcp --permanent
		sudo firewall-cmd --zone=public --add-port=7002/tcp --permanent
		sudo firewall-cmd --zone=public --add-port=9080/tcp --permanent
		sudo firewall-cmd --zone=public --add-port=9081/tcp --permanent
		sudo firewall-cmd --zone=public --add-port=9300-9400/tcp --permanent
		sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
		sudo firewall-cmd --zone=public --add-port=443/tcp --permanent
		sudo firewall-cmd --reload
		echo "completed firewall ports update"
		echo "Changing your-platform.env to no longer update packages and FW"
		sed -i s/RHEL_OR_CENTOS=.*/RHEL_OR_CENTOS=false/ $FORM_FILE
	fi
	if [ "$UBUNTU" = "true" ]; then
		sudo apt-get update
		sudo apt-get install -y curl libaio1 libncurses5 numactl iproute2 iputils-ping python2.7 python-pip tzdata unzip wget zulu-12
		echo "Changing your-platform.env to no longer update packages"
		sed -i s/UBUNTU=.*/UBUNTU=false/ $FORM_FILE
	fi
fi

if [ ! "$STANDALONE" = "true" ]; then
	#Get docker env timezone and set system timezone
	echo "setting the correct local time"
	echo $TZ > /etc/timezone
	export DEBCONF_NONINTERACTIVE_SEEN=true DEBIAN_FRONTEND=noninteractive
	dpkg-reconfigure tzdata
fi

# Create $APPD_INSTALL_DIR
mkdir -p $APPD_INSTALL_DIR


# Enable SCENARIO
if [[ $SCENARIO = *EC* ]]; then
	echo "Script Will Install/Start Enterprise Console";
	EC=true
fi
if [[ $SCENARIO = *ES* ]]; then
	echo "Script Will Install/Start Events Service";
	ES=true
fi
if [[ $SCENARIO = *CONT* ]]; then
	echo "Script Will Install/Start Controller";
	CONT=true
fi
if [[ $SCENARIO = *EUM* ]]; then
	echo "Script Will Install/Start EUM Server";
	EUM=true
fi
if [[ $SCENARIO = *SYN* ]]; then
	echo "Script Will Install/Start Synthetic Server";
	SYN=true
fi
if [[ $SCENARIO = *AA* ]]; then
	echo "Script Will Install/Start Analytics Agent";
	AA=true
	# must also have MA
	if [[ ! $SCENARIO = *MA* ]]; then
		echo "Adding MA to SCENARIO variable";
		SCENARIO="$SCENARIO MA"
	fi
fi
if [[ $SCENARIO = *MA* ]]; then
	echo "Script Will Install/Start Machine Agent";
	MA=true
fi
if [[ $SCENARIO = *DA* ]]; then
	echo "Script Will Install/Start Database Agent";
	DA=true
fi
if [[ $SCENARIO = *GEO* ]]; then
	echo "Script Will Install/Start Custom Geo Server";
	GEO=true
fi

# this will overwrite similar named install files in container 
# if there is an issue with a script than delete the file in your volume and restart container.
if [ -d "$APPD_INSTALL_DIR/your-platform-install/install-scripts" ]; then
	BACKUP_CUSTOM=$APPD_INSTALL_DIR/your-platform-install/backup-custom-install-scripts/
	mkdir -p $BACKUP_CUSTOM
	# Checking for custom install scripts
	DIR=/your-platform-install/defaults/install-scripts/
	if [ -d $DIR ]; then
		cd $DIR
		for filename in $(ls); do
			FILE_CHECK=$APPD_INSTALL_DIR$DIR$filename
			if [ -f $FILE_CHECK ]; then
				echo "Manual install file found $filename - overwriting default"
				cp -rf $FILE_CHECK /your-platform-install/install-scripts/
			else
				echo "Custom install file not found $filename - using default"
				cp -rf /your-platform-install/defaults/install-scripts/$filename /your-platform-install/install-scripts/
			fi
		done
		mv -f $APPD_INSTALL_DIR$DIR $BACKUP_CUSTOM
	fi 
else
	if [ -d "/your-platform-install" ]; then
		if [ ! -d "/your-platform-install/install-scripts" ]; then
			mkdir -p /your-platform-install/defaults/install-scripts
			cp -rf /your-platform-install/defaults/install-scripts /your-platform-install/
		fi
	fi
fi

# this will overwrite similar named startup files in container 
# if there is an issue with a script than delete the file in your volume and restart container.
if [ -d "$APPD_INSTALL_DIR/your-platform-install/startup-scripts" ]; then
	BACKUP_CUSTOM=$APPD_INSTALL_DIR/your-platform-install/backup-custom-startup-scripts/
	mkdir -p $BACKUP_CUSTOM
	# Checking for custom startup scripts
	DIR=/your-platform-install/defaults/startup-scripts/
	if [ -d $DIR ]; then
		cd $DIR
		for filename in $(ls); do
			FILE_CHECK=$APPD_INSTALL_DIR$DIR$filename
			if [ -f $FILE_CHECK ]; then
				echo "Manual startup file found $filename - overwriting default"
				cp -rf $FILE_CHECK /your-platform-install/startup-scripts/
			else
				echo "Custom startup file not found $filename - using default"
				cp -rf /your-platform-install/defaults/startup-scripts/$filename /your-platform-install/startup-scripts/
			fi
		done
		mv -f $APPD_INSTALL_DIR$DIR $BACKUP_CUSTOM
	fi
else
	if [ -d "/your-platform-install" ]; then
		if [ ! -d "/your-platform-install/startup-scripts" ]; then
			mkdir -p /your-platform-install/startup-scripts
			cp -rf /your-platform-install/defaults/startup-scripts /your-platform-install/
		fi
	fi
fi

# Installation of various components
if [ "$EC" = "true" ]; then
	EC_INSTALL_UPGRADE_FILE=$APPD_SCRIPTS_DIR/install-scripts/install-upgrade-EC.sh
	if [ -f "$EC_INSTALL_UPGRADE_FILE" ]; then
		chmod +x $EC_INSTALL_UPGRADE_FILE
		. $EC_INSTALL_UPGRADE_FILE
	else
		echo "EC install file not found here - $EC_INSTALL_UPGRADE_FILE"
	fi
fi

# Ensure the EC is started to allow the install of other services
if [ "$EC" = "true" ]; then
	EC_START_FILE=$APPD_SCRIPTS_DIR/startup-scripts/start-EC.sh
	if [ -f "$EC_START_FILE" ]; then
		chmod +x $EC_START_FILE
		. $EC_START_FILE
	else
		echo "EC Server startup file not found here - $EC_START_FILE"
	fi
fi

if [ "$CONT" = "true" ]; then
	CONT_INSTALL_UPGRADE_FILE=$APPD_SCRIPTS_DIR/install-scripts/install-upgrade-Controller.sh
	if [ -f "$CONT_INSTALL_UPGRADE_FILE" ]; then
		chmod +x $CONT_INSTALL_UPGRADE_FILE
		. $CONT_INSTALL_UPGRADE_FILE
	else
		echo "Controller install file not found here - $CONT_INSTALL_UPGRADE_FILE"
	fi
fi

if [ "$ES" = "true" ]; then
	ES_INSTALL_UPGRADE_FILE=$APPD_SCRIPTS_DIR/install-scripts/install-upgrade-ES.sh
	if [ -f "$ES_INSTALL_UPGRADE_FILE" ]; then
		chmod +x $ES_INSTALL_UPGRADE_FILE
		. $ES_INSTALL_UPGRADE_FILE
	else
		echo "Events Services install file not found here - $ES_INSTALL_UPGRADE_FILE"
	fi
fi

# CONT and ES must be started before installing some other components
if [ "$CONT" = "true" ]; then
	CONT_START_FILE=$APPD_SCRIPTS_DIR/startup-scripts/start-Controller.sh
	if [ -f "$CONT_START_FILE" ]; then
		if [ -f $APPD_INSTALL_DIR/license.lic ]; then
			cp $APPD_INSTALL_DIR/license.lic $APPD_INSTALL_DIR/appdynamics/controller/
		fi
		chmod +x $CONT_START_FILE
		. $CONT_START_FILE
	else
		echo "EC Server startup file not found here - $CONT_START_FILE"
	fi
fi

if [ "$ES" = "true" ]; then
	ES_START_FILE=$APPD_SCRIPTS_DIR/startup-scripts/start-ES.sh
	if [ -f "$ES_START_FILE" ]; then
		chmod +x $ES_START_FILE
		. $ES_START_FILE
	else
		echo "ES Server startup file not found here - $ES_START_FILE"
	fi
fi


if [ "$EUM" = "true" ]; then
	EUM_INSTALL_UPGRADE_FILE=$APPD_SCRIPTS_DIR/install-scripts/install-upgrade-EUM.sh
	if [ -f "$EUM_INSTALL_UPGRADE_FILE" ]; then
		chmod +x $EUM_INSTALL_UPGRADE_FILE
		. $EUM_INSTALL_UPGRADE_FILE
	else
		echo "EUM Server install file not found here - $EUM_INSTALL_UPGRADE_FILE"
	fi
fi

if [ "$SYN" = "true" ]; then
	SYN_INSTALL_UPGRADE_FILE=$APPD_SCRIPTS_DIR/install-scripts/install-upgrade-SYN.sh
	if [ -f "$SYN_INSTALL_UPGRADE_FILE" ]; then
		chmod +x $SYN_INSTALL_UPGRADE_FILE
		. $SYN_INSTALL_UPGRADE_FILE
	else
		echo "Synthetic Server install file not found here - $SYN_INSTALL_UPGRADE_FILE"
	fi
fi

if [ "$MA" = "true" ]; then
	MA_INSTALL_UPGRADE_FILE=$APPD_SCRIPTS_DIR/install-scripts/install-upgrade-MA.sh
	AA_INSTALL_UPGRADE_FILE=$APPD_SCRIPTS_DIR/install-scripts/install-upgrade-AA.sh
	if [ -f "$MA_INSTALL_UPGRADE_FILE" ]; then
		chmod +x $MA_INSTALL_UPGRADE_FILE
		. $MA_INSTALL_UPGRADE_FILE
		# adding analytics agent if applicable
		if [ "$AA" = "true" ]; then
			if [ -f "$AA_INSTALL_UPGRADE_FILE" ]; then
				chmod +x $AA_INSTALL_UPGRADE_FILE
				. $AA_INSTALL_UPGRADE_FILE
			else
				echo "Analytics Agent install file not found here - $AA_INSTALL_UPGRADE_FILE"
			fi
		fi
	else
		echo "Machine Agent install file not found here - $MA_INSTALL_UPGRADE_FILE"
	fi
fi

if [ "$DA" = "true" ]; then
	DA_INSTALL_UPGRADE_FILE=$APPD_SCRIPTS_DIR/install-scripts/install-upgrade-DA.sh
	if [ -f "$DA_INSTALL_UPGRADE_FILE" ]; then
		chmod +x $DA_INSTALL_UPGRADE_FILE
		. $DA_INSTALL_UPGRADE_FILE
	else
		echo "Database Agent install file not found here - $DA_INSTALL_UPGRADE_FILE"
	fi
fi

if [ "$GEO" = "true" ]; then
	GEO_INSTALL_UPGRADE_FILE=$APPD_SCRIPTS_DIR/install-scripts/install-upgrade-GEO.sh
	if [ -f "$GEO_INSTALL_UPGRADE_FILE" ]; then
		chmod +x $GEO_INSTALL_UPGRADE_FILE
		. $GEO_INSTALL_UPGRADE_FILE
	else
		echo "Custom Geo Server install file not found here - $GEO_INSTALL_UPGRADE_FILE"
	fi
fi

# Ensuring appropriate permissions for deployment
echo "Setting correct permissions"
chown -R nobody:users $APPD_SCRIPTS_DIR
chown -R nobody:users $APPD_INSTALL_DIR

# Start the AppDynamics Services
echo "Starting AppDynamics Services"



if [ "$EUM" = "true" ]; then
	EUM_START_FILE=$APPD_SCRIPTS_DIR/startup-scripts/start-EUM.sh
	if [ -f "$EUM_START_FILE" ]; then
		chmod +x $EUM_START_FILE
		. $EUM_START_FILE
	else
		echo "EUM Server startup file not found here - $EUM_START_FILE"
	fi
fi

if [ "$SYN" = "true" ]; then
	SYN_START_FILE=$APPD_SCRIPTS_DIR/startup-scripts/start-SYN.sh
	if [ -f "$SYN_START_FILE" ]; then
		chmod +x $SYN_START_FILE
		. $SYN_START_FILE
	fi
fi

if [ "$MA" = "true" ]; then
	MA_START_FILE=$APPD_SCRIPTS_DIR/startup-scripts/start-MA.sh
	if [ -f "$MA_START_FILE" ]; then
		chmod +x $MA_START_FILE
		. $MA_START_FILE
	else
		echo "Machine Agent startup file not found here - $MA_START_FILE"
	fi
fi

if [ "$DA" = "true" ]; then
	DA_START_FILE=$APPD_SCRIPTS_DIR/startup-scripts/start-DA.sh
	if [ -f "$DA_START_FILE" ]; then
		chmod +x $DA_START_FILE
		. $DA_START_FILE
	else
		echo "Database Agent startup file not found here - $DA_START_FILE"
	fi
fi

if [ "$GEO" = "true" ]; then
	GEO_START_FILE=$APPD_SCRIPTS_DIR/startup-scripts/start-GEO.sh
	if [ -f "$GEO_START_FILE" ]; then
		chmod +x $GEO_START_FILE
		. $GEO_START_FILE
	else
		echo "Custom Geo Server startup file not found here - $GEO_START_FILE"
	fi
fi

if [ "$CONT" = "true" ]; then
	if [ -f $APPD_INSTALL_DIR/license.lic ]; then
		mv -f $APPD_INSTALL_DIR/license.lic $APPD_INSTALL_DIR/appdynamics/controller/
	fi
fi

echo "Finished running script"