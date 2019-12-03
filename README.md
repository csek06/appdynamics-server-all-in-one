# AppDynamics Server All-in-One

This is a docker container or Standalone Script to install/run an On-Premise Deployment of AppDynamics - https://www.appdynamics.com/

NOTE - This should only be used for Demo / Small environments and is not intended for a Production installation.


## Component Installations this Script Can Handle
* Enterprise Console
* Controller
* Events Server
* EUM Server
* Synthetic Server
* Custom GEO Server
* Machine Agent
* Analytics Agent (When chosen, will also run Machine Agent as its bundled)
* Database Agent

## System Requirements
This is intended to be a light-weight installation, however the following minimum specs should be sufficient

|Device | Minimum | Recommended|
|--- | --- | ---|
|CPU Cores | 8 | 16|
|RAM | 16GB | 32GB|
|Disk Space | 500GB | 1 TB|

* For disk space, note actual install is less than 1GB however once AppD starts monitoring transactions your data pool will fill up.

## Standalone Script OS Supportability
* RHEL
* CentOS
* Ubuntu

# Getting Started
## Your Platform Configuration
This will check for and utilize the 'your-platform.env' file located within /opt/appdynamics directory (DOCKER) or in the same directory as the 'firstrun.sh' script file (STANDALONE install). If you don't have the file already downlaoded/modified and placed into the directory a default will be copied over and utilized. You will need to modify 'your-platform.env' prior to installation.
For the best use of this feature, modify the entire file and copy to each host that will be running all of your appd dockers/hosts and utilize the SCENARIO variable outlined below.


### Install Scenarios -- Platform Component Installation
By default, this will install the latest version of each component found on download.appdynamics.com, and (IN A FUTURE RELEASE) will auto update itself to the latest version on each container start or execution of 'firstrun.sh' script (STANDALONE), but if you want to run a different version (to go back to the previous version perhaps), modify your-platform.env file appropriately. 

SCENARIO variable is treated as a string, adding any text containing the substrings below will add the component(s).
* EC = Enterprise Console
* CONT = Controller
* ES = Events Service
* EUM = End User Monitoring Server
* SYN = Synthetic Server
* GEO = Custom Geo Server for Browser RUM
* MA = Machine Agent
* AA = Analytics Agent
* DA = Database Agent 

### Port Requirements for Components (Expose these at the container via -p command or ensure --net="host" is used)
* Enterprise Console: 9191
* Controller: 8090, 8181
* Events Service: 9080, 9081
* End User Monitoring: 7001, 7002
* Synthetic Server: 10001, 10002, 10101, 10102, 12101, 12102, 16101, 16102 (optional 16101 and 16102 are for AppD externally hosted agents)
* Custom Geo Server: 8080 (Configurable, internal container port needs to be 8080 however)
* Machine Agent: No inbound communication (no need to expose)
* Database Agent: No inbound communication (no need to expose)
* Analytics Agent: 9090, 9091

## Pre-install Notes
1. You can download the latest software at download.appdynamics.com and place the binaries of the enterprise console (optional components) in the 'APPD_INSTALL_DIR' (host directory for docker) or in the same directory as the 'firstrun.sh' script file. Otherwise, the script will download it for you if you have given your AppDynamics Community credentials in the 'your-platform.env' file which will be placed in '/opt/appdynamics'.
2. You can place your 'license.lic' file in '/opt/appdynamics' or directory of 'firstrun.sh' before install and it will activate on initial build or upon startup of container. This is handy for updating your license file periodically.
3. DOCKER USERS - If you are running on anything other than Unraid OS you can open a console to your container via 
   ```
   docker exec -i -t appdynamics-server-all-in-one /bin/bash
   ```
   * Unraid users - simply click the container in your web ui and select ">_ console"
4. AppDynamics Software will be installed in </opt/appdynamics>/appdynamics directory (DOCKER) or /opt/appdynamics for Standalone (to change this please see below section 'Your Platform Configuration'. This allows you to view/modify contents easily from your host. You can also delete and recreate the container while data persists.
5. If your installation goes sour, backup your license file, delete the folder </opt/appdynamics>/appdynamics and restart the container.
6. DOCKER USERS - You can monitor the the logs of your container by issuing the following command
	```
	docker logs -f container-name
	```
	Tip - ``` docker ps ``` - this command will list all containers

## Standalone Script Method
1. Download the entire source code and place it in a directory of your choice
2. Execute the firstrun.sh script this will create a template your-platform.env file in the install directory (default /opt/appdynamics)
3. Modify your-platform.env file to suit your needs.
4. Execute the firstrun.sh script to install and start all of your components
	
## Docker Compose Method
Ensure you have docker-compose installed on your system.
1. Download the sample docker-compose.yml and /install-scripts/your-platform.env files into a single directory.
2. Modify the files if necessary, note if you don't download the appd binaries you will need to enter your appd community credentials into the .env file.
3. Execute the below command in the directory you downloaded the yml and env file.
   ```
   docker-compose up -d
   ```
## DOCKER Install On Unraid OS Method:
On Unraid, install from the Community Applications and enter the app folder location, your Appdynamics Community Email and Password. Note: I am not storing your password or doing anything malicious it is required to download the AppDynamics binary from the website, also note is not required if you choose to download the latest version and place it in your app directory. All source code for the installation is found here on Github.
* By default this will install all components in a single container. If this is not your intended install, please see the section 'Install Scenarios' below.

## DOCKER Install On Other Platforms (like Ubuntu or Synology 5.2 DSM, etc.) Method:
On other platforms, you can run this docker with the following command:
```
docker run -d --name="appdynamics-server-all-in-one" --net="host" -v /host/install/dir:/opt/appdynamics:rw -v /etc/localtime:/etc/localtime:ro csek06/appdynamics-server-all-in-one
```
* Replace the "/opt/appdynamics" with your choice of host location
* If the -v /etc/localtime:/etc/localtime:ro mapping causes issues, you can try -e TZ="<timezone>" with the timezone in the format of "America/New_York" instead

## Sample Docker Run Commands

### Enterprise Console and Controller
```
docker run -d --name="appdynamics-server-EC-CONT" --net="host" -p 9191:9191 -p 8090:8090 -p 8181:8181 -v /host/install/dir:/opt/appdynamics:rw -v /etc/localtime:/etc/localtime:ro csek06/appdynamics-server-all-in-one
```

### Install Enterprise Console, Controller, Events Service
```
docker run -d --name="appdynamics-server-EC-Cont-ES" --net="host" -p 9191:9191 -p 8090:8090 -p 8181:8181 -p 9080:9080 -p 9081:9081 -v /host/install/dir:/opt/appdynamics:rw -v /etc/localtime:/etc/localtime:ro csek06/appdynamics-server-all-in-one
```

### Install End User Monitoring Server
```
docker run -d --name="appdynamics-server-EUM" --net="host" -p 7001:7001 -p 7002:7002 -v /host/install/dir:/opt/appdynamics:rw -v /etc/localtime:/etc/localtime:ro csek06/appdynamics-server-all-in-one
```

### Install Synthetic Server
```
docker run -d --name="appdynamics-server-SYN" --net="host" -p 10001-10002:10001-10002 -p 10101-10102:10101-10102 -p 12101-12102:12101-12102 -p 16101-16102:16101-16102 -v /host/install/dir:/opt/appdynamics:rw -v /etc/localtime:/etc/localtime:ro csek06/appdynamics-server-all-in-one
```

### Install Custom Geo Server for Browser RUM
```
docker run -d --name="appdynamics-server-GEO" --net="host" -p 80:80 -v /host/install/dir:/opt/appdynamics:rw -v /etc/localtime:/etc/localtime:ro csek06/appdynamics-server-all-in-one
```

### Install Machine Agent
```
docker run -d --name="appdynamics-server-MA" --net="host" -e AppdUser="john@doe.com" -e AppdPass="XXXX" -e CONTROLLER_HOST=192.168.2.X -e CONTROLLER_PORT=8090 -e SCENARIO=MA -e -v /host/install/dir:/opt/appdynamics:rw -v /etc/localtime:/etc/localtime:ro csek06/appdynamics-server-all-in-one
```
Additional Optional Variables - configured within your-platform.env
* MA_ENABLE_SIM - (true | false) Enable server visibility for container
* MA_ENABLE_SIM_DOCKER - (true | false) Enable host server visibility https://docs.appdynamics.com/display/CLOUD/Monitoring+Docker+Containers
   * REQUIRED paths if true
   ```
   -v /var/run/docker.sock:/var/run/docker.sock:ro -v /:/:ro
   ```

### Install Analytics Agent
```
docker run -d --name="appdynamics-server-AA" --net="host" -p 9090:9090 -p 9091:9091 -e AppdUser="john@doe.com" -e AppdPass="XXXX" -e EVENTS_SERVICE_HOST=192.168.2.X -e EVENTS_SERVICE_PORT=9080 -e CONTROLLER_HOST=192.168.2.X -e CONTROLLER_PORT=8090 -e SCENARIO=AA -v /host/install/dir:/opt/appdynamics:rw -v /etc/localtime:/etc/localtime:ro csek06/appdynamics-server-all-in-one
```

### Install Database Agent
```
docker run -d --name="appdynamics-server-DA" --net="host" -e AppdUser="john@doe.com" -e AppdPass="XXXX" -e CONTROLLER_HOST=192.168.2.X -e CONTROLLER_PORT=8090 -e SCENARIO=DA -e -v /host/install/dir:/opt/appdynamics:rw -v /etc/localtime:/etc/localtime:ro csek06/appdynamics-server-all-in-one
```

# Post Install Validation Steps
The install process takes about 15 minutes on recent hardware. You can monitor the install process via the logs - docker command below.
	```
	docker logs -f container-name
	```
	
* Login - admin
* Password - appd

Once installed, open the WebUI at http://CONTROLLERHOST:9191/ and validate that your controller, MySQL DB, and Events Service are running.
1. Navigate to http://CONTROLLERHOST:7001/eumaggregator/ping to validate the EUM server started.
2. Navigate to http://CONTROLLERHOST:8090/controller/#/location=LICENSE_MANAGEMENT_PEAK_USAGE&timeRange=last_1_hour.BEFORE_NOW.-1.-1.60 to validate your license has been applied.

# Changelog:
* 2019-12-03 - Implemented Synthetic Server, Avoid online lookup via FILENAME variable feature, minor code fixes
* 2019-11-21 - Created docker-compose file, Standardized on Install Directory, minor code fixes
* 2019-10-17 - Standardized on using FORM, Modularized script to install components outside of Docker, minor code fixes
* 2019-08-05 - Implemented FORM feature: see 'FORM' section above
* 2019-07-31 - Implemented Custom Geo Server for Browser RUM
* 2019-07-30 - Implemented Analytics Agent, Implemented Deployment Sizing Variable, minor code fixes
* 2019-03-14 - Implemented Database Agent
* 2019-03-11 - Implemented Machine Agent
* 2019-03-05 - Separated install/startup scripts - Instrumented Install Scenarios
* 2019-02-28 - Release 1.0.0 - Removed manual post-installation steps. Everything is now automatic!
* 2019-02-27 - Changed startup script to validate if software is installed.
* 2019-02-26 - Initial release - successfully downloads and installs Enterprise Console / Controller / Events Service / EUM Server (it will not upgrade and expects a clean slate in the config directory - known bugs around deleting downloaded files)
* 2019-02-25 - Initial release - still not completely functional - only downloads binary for installation at this point.
