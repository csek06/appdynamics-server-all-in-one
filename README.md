# Appdynamics Server (Controller) All-in-One

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
Once installed, open the WebUI at http://SERVERIP:SERVERPORT/.

# Changelog:
2019-02-26 - Initial release - still not completely functional - only downloads binary for installation at this point.
