#!/bin/bash

# Checking for license file and activating eum (outside of install so if user placed a new license file)
# This needs to run while EUM DB is running // need to put a check in place to validate it is running
LICENSE_OG="$APPD_INSTALL_DIR/license.lic"
LICENSE_LOC="$APPD_INSTALL_DIR/appdynamics/controller/license.lic"
if [ -f "$APPD_INSTALL_DIR/appdynamics/EUM/jre/bin/java" ]; then
	export JAVA_HOME=$APPD_INSTALL_DIR/appdynamics/EUM/jre
fi
cd $APPD_INSTALL_DIR/appdynamics/EUM/eum-processor/
if [ -f $LICENSE_OG ]; then
	./bin/provision-license $LICENSE_OG
fi
if [ -f $LICENSE_LOC ]; then
	./bin/provision-license $LICENSE_LOC
fi
