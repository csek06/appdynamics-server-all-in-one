# AppDynamics Server (Controller) All-in-One

This is a docker container for an On-Premise Deployment of AppDynamics - https://www.appdynamics.com/

NOTE - This should only be used for Demo / Small environments and is not intended for a Production installation.

Install On unRaid:
On unRaid, install from the Community Applications and enter the app folder location, your Appdynamics Community Email and Password. Note: I am not storing your password or doing anything malicious it is required to download the AppDynamics binary from the website, also note is not required if you choose to download the latest version and place it in your app directory. All source code for the installation is found here on Github. 

Install On Other Platforms (like Ubuntu or Synology 5.2 DSM, etc.):
On other platforms, you can run this docker with the following command:

docker run -d --name="appdynamics-server-all-in-one" --net="host" -p 9191 -p 8090 -p 8181 -e AppdUser="john@doe.com" -e AppdPass="XXXX" -v /path/to/config/:/config:rw -v /etc/localtime:/etc/localtime:ro csek06/appdynamics-server-all-in-one

Replace the AppdUser variable (john@doe.com) with your AppDynamics community  login email.
Replace the AppdPass variable (XXXX) with your AppDynamics community  login password.
Replace the "/path/to/config" with your choice of location
If the -v /etc/localtime:/etc/localtime:ro mapping causes issues, you can try -e TZ="<timezone>" with the timezone in the format of "America/New_York" instead

Optional Variables for the run command
By default, this will install the latest version on downloads.appdynamics.com, and will auto update itself to the latest version on each container start, but if you want to run a different version (to go back to the previous version perhaps), include the following environment variable in your docker run command -e VERSION="X.X.X.X"

# First Install Steps
The install process takes about 15 minutes on recent desktops. You can monitor the install process via the logs.


Login - admin
Password - appd

Once installed, open the WebUI at http://SERVERIP:9191/ and validate that your controller, MySQL DB, and Events Service are running.
1. Navigate to http://SERVERIP:8090/controller/admin.jsp and login with password 'appd'
2. Change the below 4 settings and click the save button on EACH field
    eum.beacon.host - localhost:7001
    eum.beacon.https.host - localhost:7002
    eum.cloud.host - localhost:7001
    eum.es.host - localhost
3. While still in the admin.jsp find the 'appdynamics.es.eum.key' field and copy the value to your clipboard should be something like 'ef9c9029-b9e6-422b-996d-50c0996c509b'
4. Stop and Start the controller (both with DB) - you can do this from the Enterprise Console located at http://SERVERIP:9191/
5. Navigate to /config/appdynamics/EUM/eum-processor/bin/eum.properties change the analytics.accountAccessKey to the key you copied in step 3 and save/exit.
6. Start EUM Server - 
  cd /config/appdynamics/EUM/eum-processor/
  ./bin/eum.sh start
  To stop you can run ./bin/eum.sh stop
7. Navigate to http://SERVERIP:7001/eumaggregator/ping to validate the EUM server started.
8. Download and place your license in /config/appdynamics/controller/controller/
    Your license should update (within 5 minutes) and can be found at http://SERVERIP:8090/controller/#/location=LICENSE_MANAGEMENT_PEAK_USAGE&timeRange=last_1_hour.BEFORE_NOW.-1.-1.60

# Changelog:
2019-02-26 - Initial release - successfully downloads and installs Enterprise Console / Controller / Events Service / EUM Server (it will not upgrade and expects a clean slate in the config directory - known bugs around deleting downloaded files)

2019-02-25 - Initial release - still not completely functional - only downloads binary for installation at this point.
