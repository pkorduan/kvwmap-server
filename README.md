# kvwmap-server

The git repository [pkorduan/kvwmap-server](https://github.com/pkorduan/kvwmap-server/) include all files to install and run a container based on the docker image [pkorduan/kvwmap-server](https://registry.hub.docker.com/u/pkorduan/kvwmap-server/).

The kvwmap-server contain the Web-GIS application kvwmap from the git repo [srahn/kvwmap](https://github.com/srahn/kvwmap), an [Apache Web Werver](http://httpd.apache.org/),
[MapServers](http://mapserver.org/) [phpMapScript](http://mapserver.org/mapscript/php/index.html)
as well as a [MySQL](http://www.mysql.com/) database for user and map context and [PostgreSQL](http://www.postgres.org) database with [PostGIS](http://www.postgis.org) extension
for geodata. For loading and exporting geodata with ogr2ogr the image [geodata/gdal](https://hub.docker.com/r/geodata/gdal/) will be used.

## Installation
The preferred way to install the `pkorduan/kvwmap-server` image and run the container onto
your system is to clone the kvwmap-server repository from github first and than install
all required components with the included administration script `dcm` (docker container manager).

### Pull kvwmap-server
**Note:** You must be logged in as root and have installed at least the debian
package git to use git and run the dcm script on your host successfully.
```
apt-get update && apt-get install -y \
  apt-utils \
  git
```

Clone the `pkorduan/kvwmap-server` repository from github in to your user
directory. Assume you have a user directory /home/gisadmin
```
git clone https://github.com/pkorduan/kvwmap-server.git
```
Logout as user gisadmin

### Configure kvwmap-server
$OS_USER is by default gisadmin and $USER_DIR /home/gisadmin
If you have cloned kvwmap-server repository at a special place other than /home/gisadmin copy the file config-default to config in config directory and make your changes.
You may change the name of the user in $OS_USER
OS_USER="your_user_name"
OS_USER_EXISTS=false
You may change the direktory where kvwmap-server has been cloned
USER_DIR="your_user_dir"
You may change the directory where the Volumes for the docker container will reside
DOCKER_ROOT="your/directory"
In the following $OS_USER means the user that you have defined in config or config-default file.

### Clone kvwmap-server repository
Login to your remote server via ssh as other user than $OS_USER. Go to the directory $USER_DIR.
The next step do not as user $OS_USER and $OS_USER must have no open connections to the server, because we want to change its uid and gid.
You must run dcm script allways as user root other than you have enabled your $OS_USER to execute docker commands.
```
kvwmap-server/dcm install kvwmap
```
This scrpit should ended up with the message: "Die Installation ist erfolgreich abgeschlossen."
Now you can logout and login again as $OS_USER. All Files in $USER_DIR will own now $OS_USER.

### Configure containers
Each container used by kvwmap have its own config file in $USER_DIR/etc
wwwdata/volumes for container wwwdata
mysql/env_and_volumes for container mysql-server
postgresql/env_and_volumes for container pgsql-server
gdal/env_and_volumes for container gdal
web/env_and_volumes for container web

More 3rdparty container can configured in kvwmap-server/cargo-available and cargo-enabled.
Change the dcm files in cargo-available and create links in cargo-enabled to include theses containers.
Consider, that changes under kvwmap-server will be overwritten by git pull or git merge commands. Save your changes bevore updating kvwmap-server.

### Start kvwmap-server
Start the containers with volumes and link it together. You will be asked to choose initial passwords for the MySQL root and PostgreSQL postgres super user as well as for a kvwmap user. The Password for kvwmap user will be used as initial password for the database access to the kvwmap databases, for the phpMyAdmin web client, which has the alias userDbAdmin, and for the admin page of the web application kvwmap itself.
```
dcm run all
```

After this step the container named web, pgsql-server and mysql-server shoud be
set up and run. The output of `docker ps -a` is shown.

### Install kvwmap web application
The default Protocol for using kvwmap should be HTTPS.
You can remove the commented out line SSLRequireSSL in /home/gisadmin/etc/apache2/sites-available/kvwmap.conf to enable HTTPS, but must install the required certificate files by yourself. Reload Apache in web container then with:
```
docker exec web service apache2 reload
```

To init the kvwmap app open a browser and call the kvwmap install script with the url of your host.
`http[s]://{yourserver}/kvmwmap/install.php`

Then click on the button "Installation starten".
The result will be open in a new browser tab. Go to the end of the page and click on the link "Login" and login with:

`user: kvwmap and password: KvwMapPW1 or your initial kvwmap password.`

Ignore the Warning: fclose(): 5 is not a valid stream resource in /var/www/apps/kvwmap/class/log.php on line 106

We recommend to change the passwords for mysql, postgres and kvwmap users
after the initial installation. Further configuration settings can be performed
in config.php. See the kvwmap documentation for more information at:
<http://www.kvwmap.de>

### Unistall kvwmap-server
This stoped all container, remove it, remove all images and remove the volumes inclusive of the database volumes.
Be careful with this command, because it will remove also the data in the directories /var/www and db, etc, kvwmap-server in your home directory.
```
dcm uninstall all
```

If you only whant to remove the container and images use this commands:
```
dcm rm all
```

## Server status
To check if everything works well, you have different options.
```
dcm status all
```
shows the status of the containers. Good is a message like this:
```
Status des Containers mysql-server:
OK - mysql-server is running. IP: 172.17.0.1, StartedAt: 2015-08-21T14:24:08.637094394Z
Status des Containers pgsql-server:
OK - pgsql-server is running. IP: 172.17.0.2, StartedAt: 2015-08-21T14:24:10.691315837Z
Status des Containers web:
OK - web is running. IP: 172.17.0.3, StartedAt: 2015-08-21T14:24:11.059835363Z
```
To see the containers you also can use the regularly docker command ps. 
```
docker ps -a
```
The parameter -a shows you also the not running container. The command inspect shows you the parameter of a container. Use the name of the container to get detailed information about it.
```
docker inspect web
```
To see the log file of the web containers type:
```
docker logs web
```

## Detailed installation and update description

### Install docker
The installation of docker will be performed in the script dcm which has been downloaded with this repository.
The install command of the dcm script make use of the install script at get.docker.com to install docker.
Generally you could have installed docker also as a debian package as described in docker docu [here] (https://docs.docker.com/installation/debian/#installation) But the package must not include the newest version. Therefor it is recommended to use the docker install script from get.docker.com, as we do in the dcm install command.

### Update docker
To update the docker Engine run the following command on your host system:
```
curl -sSL https://get.docker.com/ | sh
```
You will see the new version of docker client and server after installing with this script. To find the current version of docker engine and client you can always use the command:
```
docker version
```
### Update this repo on your host system
Pull a new version of the kvwmap-server repo by typing
```
git pull origin master
```
in your directory $USER_DIR/kvwmad-server. This will download all changes in files of this repository, but not the container itself or the images from which the containers has been run. Consider that the downloaded files will have the owner of the user that pull the repo. All files in kvwmap-server should be owned by gisadmin and group gisadmin.
A known problem when download an repo is, that files has been changed without commiting it to the repo.
```
error: Your local changes to the following files would be overwritten by merge:
```
In this case you can find the difference between the local file and the previous version of this file by:
```
git diff <file_name_that_has_been_changed>
```
If you whant to commit this change add the file to the stage
```
git add <file_name_that_has_been_changed>
```
and commit it with an appropriated message.
```
git commit -m "Changed the file: <file_name_that_has_been_changed> because there was a typo inside."
```
Than you should be able to pull the new version from the remote repo.
```
git pull origin master
```
When you do so, the remote master will be merged into the local changed repo. Therefor you will be asked to leave a merge message. Do can it leave as it is and quit with Cntl.-X.
But do not forget to push your committed change also to the remote repo, so that outher can also benefit from it.
```
git push origin master
```
Therefore you must be a contributor to this repo. Ask the maintainer to become a contributor to this repo.

A new image can be created localy with the build command of docker. But to run the new image the old container must be stopped and the new one created. Therefore the script dcm can be used with the following parameters.
To rebuild the web container for apache2 with kvwmap run the following command:
```
dcm rebuild web
```
This will stop and remove only the web container, remove the kvwmap-server image, pull the image kvwmap-server:latest from [dockerhub](https://hub.docker.com/r/pkorduan/kvwmap-server/) and run again the web container as when you start first.
To not build the image, but download the latest from dockerhub you can use the dcm script with reload option
```
dcm reload web
```
To manually rebuild the web container with another version of mysql or postgres change the version numbers in env_and_volumes script for the constants MYSQL_IMAGE_VERSION or POSTGRES_IMAGE_VERSION and call the dcm script with the parameter rebuild all. You can download the new version manually before restarting the web container. This will save some downtime of the kvwmap application.
```
docker pull pkorduan/postgis:<new_version_number>
sed -i -e "s|POSTGRESQL_IMAGE_VERSION=9.4|POSTGRESQL_IMAGE_VERSION=<new_version_number>|g" \
$USER_DIR/kvwmap-server/dcm
dcm rebuild all
