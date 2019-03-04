# Checking for license file and activating eum (outside of install so if user placed a new license file)
# This needs to run while EUM DB is running // need to put a check in place to validate it is running
LICENSE_OG="/config/license.lic"
LICENSE_LOC="/config/appdynamics/controller/controller/license.lic"
if [ -f $LICENSE_OG ]; then
  mv -f $LICENSE_OG $LICENSE_LOC
fi
if [ -f $LICENSE_LOC ]; then
  /config/appdynamics/EUM/eum-processor/bin/provision-license $LICENSE_LOC
fi