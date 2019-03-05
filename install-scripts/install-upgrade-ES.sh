#!/bin/bash

# check if Events Service is installed
if [ -f /config/appdynamics/controller/events-service/processor/bin/events-service.sh ]; then
  INSTALLED_VERSION=$(find /config/appdynamics/platform/platform-admin/archives/platform-configuration/ -name "*.yml" -type f -exec grep -oPz '(events-service\"\s.*version\:\s\")\K(.*?)(?=\"\s.*build)' {} \;)
  echo "Events Service: $INSTALLED_VERSION is installed"
  # check for upgrade <code to be inserted>, however upgrade path needs to be followed EC > ES > EUM > Controller
else
  echo "Installing Events Service"
  cd /config/appdynamics/platform/platform-admin/bin
  ./platform-admin.sh install-events-service  --profile dev --hosts localhost
fi

