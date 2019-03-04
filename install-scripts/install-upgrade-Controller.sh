#!/bin/bash

# check if Controller is installed
if [ -f /config/appdynamics/controller/controller/bin/controller.sh ]; then
  INSTALLED_VERSION=$(find /config/appdynamics/platform/platform-admin/archives/platform-configuration/ -name "*.yml" -type f -exec grep -oPz '(controller\"\s.*version\:\s\")\K(.*?)(?=\"\s.*build)' {} \;)
  echo "Controller: $INSTALLED_VERSION is installed"
  # check for upgrade <code to be inserted>, however upgrade path needs to be followed EC > ES > EUM > Controller
else
  echo "Installing Controller and local database"
  cd /config/appdynamics/platform/platform-admin/bin
  ./platform-admin.sh create-platform --name my-platform --installation-dir /config/appdynamics/controller
  ./platform-admin.sh add-hosts --hosts localhost
  ./platform-admin.sh submit-job --service controller --job install --args controllerPrimaryHost=localhost controllerAdminUsername=admin controllerAdminPassword=appd controllerRootUserPassword=appd mysqlRootPassword=appd
fi