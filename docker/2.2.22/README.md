# Supported tags and respective Dockerfile
	* latest [docker/dockerfile](https://github.com/pkorduan/kvwmap-server/blob/master/docker/Dockerfile)
    * 2.2.16 [docker/2.2.16/Dockerfile](https://github.com/pkorduan/kvwmap-server/blob/master/docker/2.2.16/Dockerfile)
    * 2.2.15 [docker/2.2.15/Dockerfile](https://github.com/pkorduan/kvwmap-server/blob/master/docker/2.2.15/Dockerfile)
    * 2.2.14 [docker/2.2.14/Dockerfile](https://github.com/pkorduan/kvwmap-server/blob/master/docker/2.2.14/Dockerfile)
	* 2.2.13 [docker/2.2.13/Dockerfile](https://github.com/pkorduan/kvwmap-server/blob/master/docker/2.2.13/Dockerfile)
	* 2.2.12 [docker/2.2.12/Dockerfile](https://github.com/pkorduan/kvwmap-server/blob/master/docker/2.2.12/Dockerfile)
	* 2.2.11 [docker/2.2.11/Dockerfile](https://github.com/pkorduan/kvwmap-server/blob/master/docker/2.2.11/Dockerfile)
	* 2.2.10 [docker/2.2.10/Dockerfile](https://github.com/pkorduan/kvwmap-server/blob/master/docker/2.2.10/Dockerfile)
	* 2.2.9 [docker/2.2.9/Dockerfile](https://github.com/pkorduan/kvwmap-server/blob/master/docker/2.2.9/Dockerfile)
	* 2.2.8 [docker/2.2.8/Dockerfile](https://github.com/pkorduan/kvwmap-server/blob/master/docker/2.2.8/Dockerfile)
	* 2.2.7 [docker/2.2.7/Dockerfile](https://github.com/pkorduan/kvwmap-server/blob/master/docker/2.2.7/Dockerfile)
	* 2.2.6 [docker/2.2.6/Dockerfile](https://github.com/pkorduan/kvwmap-server/blob/master/docker/2.2.6/Dockerfile)
	* 2.2.5 [docker/2.2.5/Dockerfile](https://github.com/pkorduan/kvwmap-server/blob/master/docker/2.2.5/Dockerfile)
	* 2.2.4 [docker/2.2.4/Dockerfile](https://github.com/pkorduan/kvwmap-server/blob/master/docker/2.2.4/Dockerfile)
	* 2.2.3 [docker/2.2.3/Dockerfile](https://github.com/pkorduan/kvwmap-server/blob/master/docker/2.2.3/Dockerfile)
	* 2.2.2 [docker/2.2.2/Dockerfile](https://github.com/pkorduan/kvwmap-server/blob/master/docker/2.2.2/Dockerfile)
	* 2.2.1 [docker/2.2.1/Dockerfile](https://github.com/pkorduan/kvwmap-server/blob/master/docker/2.2.1/Dockerfile)
	* 2.2.0 [docker/2.2.0/Dockerfile](https://github.com/pkorduan/kvwmap-server/blob/master/docker/2.2.0/Dockerfile)
	* 2.1.0 [docker/2.1.0/Dockerfile](https://github.com/pkorduan/kvwmap-server/blob/master/docker/2.1.0/Dockerfile)
	* 2.0.1 [docker/2.0.1/Dockerfile](https://github.com/pkorduan/kvwmap-server/blob/master/docker/2.0.1/Dockerfile)
	* 2.0.0 [docker/2.0.0/Dockerfile](https://github.com/pkorduan/kvwmap-server/blob/master/docker/2.0.0/Dockerfile)
	* 1.2.7 [docker/1.2.7/Dockerfile](https://github.com/pkorduan/kvwmap-server/blob/master/docker/1.2.7/Dockerfile)
	* 1.2.6 [docker/1.2.6/Dockerfile](https://github.com/pkorduan/kvwmap-server/blob/master/docker/1.2.6/Dockerfile)
	* 1.2.5 [docker/1.2.5/Dockerfile](https://github.com/pkorduan/kvwmap-server/blob/master/docker/1.2.5/Dockerfile)

# kvwmap-server

The git repository [pkorduan/kvwmap-server](https://github.com/pkorduan/kvwmap-server/) include all files to install and run a container based on the docker image [pkorduan/kvwmap-server](https://registry.hub.docker.com/u/pkorduan/kvwmap-server/).

The kvwmap-server contain the Web-GIS application kvwmap from the git repo [srahn/kvwmap](https://github.com/srahn/kvwmap), an [Apache Web Werver](http://httpd.apache.org/),
[MapServers](http://mapserver.org/) [phpMapScript](http://mapserver.org/mapscript/php/index.html)
as well as a [MySQL](http://www.mysql.com/) database for user and map context and [PostgreSQL](http://www.postgres.org) database with [PostGIS](http://www.postgis.org) extension
for geodata. For loading and exporting geodata with ogr2ogr the image [geodata/gdal](https://hub.docker.com/r/geodata/gdal/) will be used.

## Installation
The preferred way to install the `pkorduan/kvwmap-server` image on a blank root server is the command
```
wget -O inithost.sh https://gdi-service.de/public/kvwmap_resources/inithost && \
chmod a+x inithost.sh && \
./inithost.sh
```
The script will clone the kvwmap-server repository from github first and than install
all required components with the included administration script `dcm` (docker container manager).

Read more if you want to install on a running not blank server or to understands the steps to install WebGIS kvwmap in more detail.

### Clone kvwmap-server repository

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
You may change the host and or domainname of this server.
In the following $OS_USER means the user that you have defined in config or config-default file.

### Install ressources for docker container
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
mysql/env_and_volumes for container mysql-server
postgresql/env_and_volumes for container pgsql-server
gdal/env_and_volumes for container gdal
web/env_and_volumes for container web

More 3rdparty container can configured in kvwmap-server/cargo-available and cargo-enabled.
Change the dcm files in cargo-available and create links in cargo-enabled to include theses containers.
Consider, that changes under kvwmap-server will be overwritten by git pull or git merge commands. Save your changes bevore updating kvwmap-server.

### Run container for kvwmap
Start the containers with volumes and link it together. You will be asked to choose initial passwords for the MySQL root and PostgreSQL postgres super user as well as for a kvwmap user. The Password for kvwmap user will be used as initial password for the database access to the kvwmap databases, for the phpMyAdmin web client, which has the alias userDbAdmin, and for the admin page of the web application kvwmap itself.
```
dcm run all
```

After this step the container named web, pgsql-server and mysql-server shoud be
set up and run. The output of `docker ps -a` is shown.

### Initialize kvwmap web application
The default Protocol for using kvwmap should be HTTPS.
You can remove the commented out line SSLRequireSSL in /home/gisadmin/etc/apache2/sites-available/kvwmap.conf to enable HTTPS, but must install the required certificate files by yourself. Reload Apache in web container then with:
```
docker exec web service apache2 reload
```

To init the kvwmap app open a browser and call the kvwmap install script with the url of your host.
`http[s]://{yourserver}/kvmwmap/install.php`

Set your database account credentials with MYSQL_HOST = mysql and POSTGRES_HOST = pgsql.
Then click on the button "Installation starten".
The result will be open in a new browser tab. Go to the end of the page and click on the link "Login" and login with:

`user: kvwmap and password: KvwMapPW1 or your initial kvwmap password.`

Ignore the Warning: fclose(): 5 is not a valid stream resource in /var/www/apps/kvwmap/class/log.php on line 106

We recommend to change the passwords for mysql, postgres and kvwmap users
after the initial installation. Further configuration settings can be performed
in config.php. See the kvwmap documentation for more information at:
<http://www.kvwmap.de>

### Unistall
This stoped all container, remove it, remove all images and remove the volumes inclusive of the database volumes.
Be careful with this command, because it will remove also the data in the directories /var/www and db, etc, kvwmap-server in your home directory.
```
dcm uninstall all
```

If you only whant to remove the container and images use this commands:
```
dcm rm all
```

## Get container status
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

### Building Image ###
docker build -t pkorduan/kvwmap-server:2.0.1 .

### Run a Container ###
docker run --rm --name ms -v /home/gisadmin/kvwmap-server/docker/2.2.0/sources/mapserver.conf:/etc/apache2/conf-enabled/mapserver.conf -v /home/gisadmin/kvwmap-server/docker/2.2.0/sources/test.php:/var/www/html/test.php -p 8080:80 -d pkorduan/kvwmap-server:2.2.0

### Get Certificate with certbot ###
dcm rm web
docker run -it --rm --name certbot \
  -v "/home/gisadmin/etc/apache2/letsencrypt:/etc/letsencrypt" \
  -v "/var/lib/letsencrypt:/var/lib/letsencrypt" \
  -p 80:80 -p 443:443 \
  certbot/certbot certonly

follow the instruction of certbot and choose option 1 for standalone self installed web Server

dcm run web

# Changelog
# 2.2.16
    * Without phpmyadmin configuratin and installation on the web container
# 2.2.15
    * Security increasing for Apache
# 2.2.14
    * entrypoint (kvwmap-start) can handle signals
# 2.2.13
    * Decrease the Mapserver Version
# 2.2.12
	* inkscape library included
	* Decrease the ImageMagick Version
# 2.2.11
	* using rotatelogs for apache2 access and error logfiles, daily rotation and compression inside 000-default.conf
# 2.2.10
	* Use debian image Version 11.3
	* Install without backports
	* updated Apache Version
	* Mapserver 7.6.4
	* remove phpMyAdmin
# 2.2.9
	* Add apache module remote_ip
# 2.2.8
	* Install sendemail, libnet-ssleay-perl and libio-socket-ssl-perl
# 2.2.7
	* Upgrade apache2 to version 2.4.52
# 2.2.6
	* call ldconfig after installation of imagemagick
# 2.2.5
	* install imagemagick with disabled hdri to improve performance of image creation
# 2.2.4
	* install gsfonts and configure ImageMagick to use it
	* install jq Package for parsing JSON Text on command line
# 2.2.3
	* upgrade mapserver to 7.6.3 see https://mapserver.org/development/changelog/changelog-7-6.html#changelog-7-6
	* add --no-install-recommends to apt-get install
	* chmod to /usr/local/bin executables
# 2.2.2
	* Compile ImageMagick with rsvg support
# 2.2.1
	* install php-sqlite support for dokuwikis that uses only sqlite
	* install python3-certbot-apache
	* update phpMyAdmin to 5.0.4
	* install docker.io
	* dont run gdal container in dcm script since ogr2ogr is called with docker run command not with docker exec
# 2.2.0
	* install certbot with apt
	* install mapserver with svg symbol support 
# 2.1.0
	* install php-soap Module
# 2.0.1
	* install phpMyAdmin 5.0.2
	* install mapserver 7.6.1 with php-mapscript from git
	* install imageMagick 7 from git
	* remove all old versions below 1.2.5 from source docker directory
# 2.0.0
	* switch to debian 10.0 (buster)
	* change the package names to install php7
	* install mapserver 7.4 with phpMapScript for php7
	* use mariaDB insted of mySQL
	* add inithost.sh script to install all at once
# 1.2.7
	* Switch to http://archive.debian.org/debian for apt since jessie is no longer on debian mirrors
# 1.2.6
	* Improve install process and change doku
	* Use command hostname --fqd for HOSTNAME constante in config-default
	* Change to xterm linux in env_and_volumes and set all to a+x
	* add correct install of certbot for apache2 and debian 8
# 1.2.5
	* Add xslt Extension php-xsl
# 1.2.4
	* Add apache module expires finally, because it was not added in 1.2.2.
	* Add pgpass to web container config
	* Set image and version in env_and_volumes config of owncloud container.
	* Change owncloud install function
# 1.2.3
	* Add docker to be able to call commands in other containers
	* Add user www-data to docker group
# 1.2.2
	* Do things in kvwmap-firstrun only if not allready done
	* Enable apache mod expires
# 1.2.1
	* Use debian with tag, here jessie to ensure that dockerhub uses the same resources for installation as when build localy
	* Use ARG to set variable in Dockerfile
	* Change README to docker folder and update Tags and Changelog Section for each change in latest and in version folder
# 1.2.0
	* Start to build images in separate version folders
	* Composer for PHP
