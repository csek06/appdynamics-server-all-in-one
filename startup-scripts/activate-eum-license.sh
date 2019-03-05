#!/bin/bash

# Checking for license file and activating eum (outside of install so if user placed a new license file)
# This needs to run while EUM DB is running // need to put a check in place to validate it is running
LICENSE_OG="/config/license.lic"
LICENSE_LOC="/config/appdynamics/controller/controller/license.lic"
cd /config/appdynamics/EUM/eum-processor/
if [ -f $LICENSE_OG ]; then
  ./bin/provision-license $LICENSE_OG
fi
if [ -f $LICENSE_LOC ]; then
  ./bin/provision-license $LICENSE_LOC
fi
