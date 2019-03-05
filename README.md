# AppDynamics Server All-in-One

This is a docker container for an On-Premise Deployment of AppDynamics - https://www.appdynamics.com/

NOTE - This should only be used for Demo / Small environments and is not intended for a Production installation.
### Installed Services by Default
* Enterprise Console
* Controller with Database
* Events Server
* EUM Server

## System Requirements
This is intended to be a light-weight installation, however the following minimum specs should be sufficient

|Device | Minimum | Recommended|
|--- | --- | ---|
|CPU Cores | 8 | 16|
|RAM | 16GB | 32GB|
|Disk Space | 500GB | 1 TB|

* For disk space, note actual install is less than 1GB however once AppD starts monitoring transactions your data pool will fill up.

## Pre-install Notes
1. You can download the latest software at download.appdynamics.com and place the binaries of the enterprise console and eum server in the /path/to/config directory. Otherwise, the script will download it for you if you have given environment variables for your AppDynamics Community credentials.
2. You can place your 'license.lic' file in /path/to/config pre-install and it will activate on initial build or upon startup of container. This is handy for updating your license file periodically.
3. If you are running on anything other than Unraid you can open a console to your container via 
   ```
   docker exec -i -t appdynamics-server-all-in-one /bin/bash
   ```
   * Unraid users - simply click the container in your web ui and select ">_ console"
4. AppDynamics Software will be installed in </path/to/config>/appdynamics directory. This allows you to view/modify contents easily from your host. You can also delete and recreate the container.
5. If your installation goes sour, backup your license file, delete the folder </path/to/config>/appdynamics and restart the container.

## Install On Unraid:
On Unraid, install from the Community Applications and enter the app folder location, your Appdynamics Community Email and Password. Note: I am not storing your password or doing anything malicious it is required to download the AppDynamics binary from the website, also note is not required if you choose to download the latest version and place it in your app directory. All source code for the installation is found here on Github. 

## Install On Other Platforms (like Ubuntu or Synology 5.2 DSM, etc.):
On other platforms, you can run this docker with the following command:
```
docker run -d --name="appdynamics-server-all-in-one" --net="host" -p 9191:9191 -p 8090:8090 -p 8181:8181 -e AppdUser="john@doe.com" -e AppdPass="XXXX" -e SERVERIP=192.168.2.X -v /path/to/config/:/config:rw -v /etc/localtime:/etc/localtime:ro csek06/appdynamics-server-all-in-one
```
* Replace the AppdUser variable (john@doe.com) with your AppDynamics community login email.
* Replace the AppdPass variable (XXXX) with your AppDynamics community login password.
* Replace the SERVERIP variable (192.168.2.X) with your host IP
* Replace the "/path/to/config" with your choice of location
* If the -v /etc/localtime:/etc/localtime:ro mapping causes issues, you can try -e TZ="<timezone>" with the timezone in the format of "America/New_York" instead

## Optional Variables for the run command
By default, this will install the latest version on download.appdynamics.com, and (IN A FUTURE RELEASE) will auto update itself to the latest version on each container start, but if you want to run a different version (to go back to the previous version perhaps), include the following environment variable in your docker run command -e VERSION="X.X.X.X".

# Post Install Validation Steps
The install process takes about 15 minutes on recent desktops. You can monitor the install process via the logs.
* Login - admin
* Password - appd

Once installed, open the WebUI at http://SERVERIP:9191/ and validate that your controller, MySQL DB, and Events Service are running.
1. Navigate to http://SERVERIP:7001/eumaggregator/ping to validate the EUM server started.
2. Navigate to http://SERVERIP:8090/controller/#/location=LICENSE_MANAGEMENT_PEAK_USAGE&timeRange=last_1_hour.BEFORE_NOW.-1.-1.60 to validate your license has been applied.

# Changelog:
* 2019-02-28 - Removed manual post-installation steps. Everything is now automatic!
* 2019-02-27 - Changed startup script to validate if software is installed.
* 2019-02-26 - Initial release - successfully downloads and installs Enterprise Console / Controller / Events Service / EUM Server (it will not upgrade and expects a clean slate in the config directory - known bugs around deleting downloaded files)
* 2019-02-25 - Initial release - still not completely functional - only downloads binary for installation at this point.
