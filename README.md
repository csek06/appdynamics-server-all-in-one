# AppDynamics Server All-in-One

This is a docker container for an On-Premise Deployment of AppDynamics - https://www.appdynamics.com/

NOTE - This should only be used for Demo / Small environments and is not intended for a Production installation.


### Installed Services by Default
* Enterprise Console
* Controller with Database
* Events Server
* EUM Server

### Optional Component Installations
* Events Server
* EUM Server
* Machine Agent
* Database Agent

## System Requirements
This is intended to be a light-weight installation, however the following minimum specs should be sufficient

|Device | Minimum | Recommended|
|--- | --- | ---|
|CPU Cores | 8 | 16|
|RAM | 16GB | 32GB|
|Disk Space | 500GB | 1 TB|

* For disk space, note actual install is less than 1GB however once AppD starts monitoring transactions your data pool will fill up.

## Pre-install Notes
1. You can download the latest software at download.appdynamics.com and place the binaries of the enterprise console (optional components) in the '/path/to/config' directory. Otherwise, the script will download it for you if you have given environment variables for your AppDynamics Community credentials.
2. You can place your 'license.lic' file in '/path/to/config' before install and it will activate on initial build or upon startup of container. This is handy for updating your license file periodically.
3. If you are running on anything other than Unraid you can open a console to your container via 
   ```
   docker exec -i -t appdynamics-server-all-in-one /bin/bash
   ```
   * Unraid users - simply click the container in your web ui and select ">_ console"
4. AppDynamics Software will be installed in </path/to/config>/appdynamics directory. This allows you to view/modify contents easily from your host. You can also delete and recreate the container while data persists.
5. If your installation goes sour, backup your license file, delete the folder </path/to/config>/appdynamics and restart the container.

## Install On Unraid:
On Unraid, install from the Community Applications and enter the app folder location, your Appdynamics Community Email and Password. Note: I am not storing your password or doing anything malicious it is required to download the AppDynamics binary from the website, also note is not required if you choose to download the latest version and place it in your app directory. All source code for the installation is found here on Github.
* By default this will install all components in a single container. If this is not your intended install, please see the section 'Install Scenarios' below.

## Install On Other Platforms (like Ubuntu or Synology 5.2 DSM, etc.):
On other platforms, you can run this docker with the following command:
```
docker run -d --name="appdynamics-server-all-in-one" --net="host" -p 9191:9191 -p 8090:8090 -p 8181:8181 -e AppdUser="john@doe.com" -e AppdPass="XXXX" -e CONTROLLER_HOST=192.168.2.X -v /path/to/config/:/config:rw -v /etc/localtime:/etc/localtime:ro csek06/appdynamics-server-all-in-one
```
* Replace the AppdUser variable (john@doe.com) with your AppDynamics community login email.
* Replace the AppdPass variable (XXXX) with your AppDynamics community login password.
* Replace the CONTROLLER_HOST variable (192.168.2.X) with your host IP of the EC/Controller
* Replace the "/path/to/config" with your choice of location
* If the -v /etc/localtime:/etc/localtime:ro mapping causes issues, you can try -e TZ="<timezone>" with the timezone in the format of "America/New_York" instead
* This will install the default (Enterprise Console and Controller) components in a single container. If this is not your intended install, please see the section 'Install Scenarios' below.

## Install Scenarios -- Optional Variables for the run command
By default, this will install the latest version on download.appdynamics.com, and (IN A FUTURE RELEASE) will auto update itself to the latest version on each container start, but if you want to run a different version (to go back to the previous version perhaps), include the following environment variable in your docker run command -e VERSION="X.X.X.X" (currently only the enterprise console can be changed). If you want to change the component installation include the following environment variable in your docker run command -e SCENARIO="ECCONTESEUM" (more on this below). NOTE - you may also need to include additional variables, ensure you investigate the below sections/code.

SCENARIO variable is treated as a string, adding any text containing the substrings below will add the component(s).
* EC = Enterprise Console
* CONT = Controller
* ES = Events Service
* EUM = End User Monitoring Server
* MA = Machine Agent
* DA = Database Agent 

### (DEFAULT Installation) Enterprise Console and Controller
```
docker run -d --name="appdynamics-server-all-in-one" --net="host" -p 9191:9191 -p 8090:8090 -p 8181:8181 -e AppdUser="john@doe.com" -e AppdPass="XXXX" -e CONTROLLER_HOST=192.168.2.X -v /path/to/config/:/config:rw -v /etc/localtime:/etc/localtime:ro csek06/appdynamics-server-all-in-one
```
Additional Optional Variables
* CONTROLLER_SIZE - (demo, small, medium, large, extra-large) Ensure you have [proper Hardware requirements](https://docs.appdynamics.com/display/latest/Controller+System+Requirements)!

### Install Enterprise Console, Controller, Events Service
```
docker run -d --name="appdynamics-server-EC-Cont-ES" --net="host" -p 9191:9191 -p 8090:8090 -p 8181:8181 -e AppdUser="john@doe.com" -e AppdPass="XXXX" -e CONTROLLER_HOST=192.168.2.X -e SCENARIO=ECCONTES -v /path/to/config/:/config:rw -v /etc/localtime:/etc/localtime:ro csek06/appdynamics-server-all-in-one
```
### Install End User Monitoring Server
```
docker run -d --name="appdynamics-server-EUM" --net="host" -p 7001:7001 -p 7002:7002 -e AppdUser="john@doe.com" -e AppdPass="XXXX" -e SCENARIO=EUM -e EVENT_SERVICE_HOST=192.168.2.1 -e EUM_HOST=192.168.2.1 -e CONTROLLER_HOST=192.168.2.1 -v /path/to/config/:/config:rw -v /etc/localtime:/etc/localtime:ro csek06/appdynamics-server-all-in-one
```
* Make note of the added 'EVENT_SERVICE_HOST', 'EUM_HOST', and 'CONTROLLER_HOST' variables. These reference the host(s) in which ES/CONT/EUM is installed and running and should be modified.

Additional Optional Variables
* EUM_SIZE - (demo, split) Split is a production level install. Ensure you have [proper Hardware requirements](https://docs.appdynamics.com/display/latest/EUM+Server+Requirements)

### Install Machine Agent
```
docker run -d --name="appdynamics-server-MA" --net="host" -e AppdUser="john@doe.com" -e AppdPass="XXXX" -e CONTROLLER_HOST=192.168.2.X -e CONTROLLER_PORT=8090 -e SCENARIO=MA -e -v /path/to/config/:/config:rw -v /etc/localtime:/etc/localtime:ro csek06/appdynamics-server-all-in-one
```
* CONTROLLER_HOST - optional if running controller on same host
* CONTROLLER_PORT - optional if running controller on same host

Additional Optional Variables
* ENABLE_SIM - (true | false) Enable server visibility for container
* ENABLE_SIM_DOCKER - (true | false) Enable host server visibility https://docs.appdynamics.com/display/CLOUD/Monitoring+Docker+Containers
   * REQUIRED paths if true
   ```
   -v /var/run/docker.sock:/var/run/docker.sock:ro -v /:/:ro
   ```

### Install Database Agent
```
docker run -d --name="appdynamics-server-DA" --net="host" -e AppdUser="john@doe.com" -e AppdPass="XXXX" -e CONTROLLER_HOST=192.168.2.X -e CONTROLLER_PORT=8090 -e SCENARIO=DA -e -v /path/to/config/:/config:rw -v /etc/localtime:/etc/localtime:ro csek06/appdynamics-server-all-in-one
```
* CONTROLLER_HOST - optional if running controller on same host
* CONTROLLER_PORT - optional if running controller on same host

# Post Install Validation Steps
The install process takes about 15 minutes on recent desktops. You can monitor the install process via the logs.
* Login - admin
* Password - appd

Once installed, open the WebUI at http://CONTROLLERHOST:9191/ and validate that your controller, MySQL DB, and Events Service are running.
1. Navigate to http://CONTROLLERHOST:7001/eumaggregator/ping to validate the EUM server started.
2. Navigate to http://CONTROLLERHOST:8090/controller/#/location=LICENSE_MANAGEMENT_PEAK_USAGE&timeRange=last_1_hour.BEFORE_NOW.-1.-1.60 to validate your license has been applied.

# Changelog:
* 2019-03-14 - Implemented Database Agent, Deployment Sizing Variable
* 2019-03-11 - Implemented Machine Agent
* 2019-03-05 - Separated install/startup scripts - Instrumented Install Scenarios
* 2019-02-28 - Release 1.0.0 - Removed manual post-installation steps. Everything is now automatic!
* 2019-02-27 - Changed startup script to validate if software is installed.
* 2019-02-26 - Initial release - successfully downloads and installs Enterprise Console / Controller / Events Service / EUM Server (it will not upgrade and expects a clean slate in the config directory - known bugs around deleting downloaded files)
* 2019-02-25 - Initial release - still not completely functional - only downloads binary for installation at this point.
