# kvwmap-server

This repository include all files to install and run a container based on the docker
image [pkorduan/kvwmap-server](https://registry.hub.docker.com/u/pkorduan/kvwmap-server/).

The kvwmap-server contain a the Web-GIS application kvwmap from the git repo [srahn/kvwmap](https://github.com/srahn/kvwmap), an [Apache Web Werver](http://httpd.apache.org/),
[MapServers](http://mapserver.org/) [phpMapScript](http://mapserver.org/mapscript/php/index.html)
as well as a [MySQL](http://www.mysql.com/) database for user and map context and [PostgreSQL](http://www.postgres.org) database with [PostGIS](http://www.postgis.org) extension
for geodata. For loading and exporting geodata with ogr2ogr the image [geodata/gdal](https://hub.docker.com/r/geodata/gdal/) will be used.

## Installation
The preferred way to install the `pkorduan/kvwmap-server` image and run the container onto
your system is to clone the kvwmap-server repository from github first and than install
all required components with the included administration script `kvwmap`.

### Pull kvwmap-server
**Note:** You must be logged in as root and have installed at least the debian
packages git, wget and curl to use git and run the kvwmap script on your host successfully.

```
apt-get update && apt-get install -y \
  apt-utils \
  curl \
  git \
  wget
```

Clone the `pkorduan/kvwmap-server` repository from github in to your user
directory. Assume you have a user directory /home/gisadmin

```
$ USER_DIR=/home/gisadmin
$ cd USER_DIR
$ git clone https://github.com/pkorduan/kvwmap-server.git
```
### Install kvwmap-server
Get and install all the components that uses kvwmap-server.

```
$ kvwmap-server/kvwmap install
```

This scrpit should ended up with the message: Successfully built or a message that the image pkorduan/kvwmap-server has been successfull pulled.

### Start kvwmap-server
Start the containers with volumes and link it together. You will be asked to
choose passwords for the MySQL root and PostgreSQL postgres super user as well as for a kvwmap user. The Password for kvwmap user will be used as initial password for the database access to the kvwmap databases, for the phpMyAdmin web client which has the alias userDbAdmin and for the admin page of the web application kvwmap itself.

```
$ kvwmap run all
```

After this step the container named web, pgsql-server and mysql-server shoud be
set up and run. The output of `docker ps -a` is shown.

### Install kvwmap web application
Open a browser and call the kvwmap install script with the url of your host.

`http://yourserver/kvmwmap/install.php`

There should be no error messages and a hint that you now can login with

`user: kvwmap and password: kvmwap`

Ignore the Warning: fclose(): 5 is not a valid stream resource in /var/www/apps/kvwmap/class/log.php on line 106

We recommend to change the passwords for mysql, postgres and kvwmap users
after the initial installation. Further configuration settings can be performed
in config.php. See the kvwmap documentation for more information at:
<http://www.kvwmap.de>

### Unistall kvwmap-server
This stoped all container, remove it, remove all images and remove the volumes inclusive of the database volumes.
Be careful with this command, because it will remove also the data in the directories /var/www and db, etc, kvwmap-server in your home directory.

```
$ kvwmap uninstall
```

If you only whant to remove the container and images use this commands:

```
$ kvwmap stop all
$ kvwmap remove all
```

## Server status
To check if everything works well, you have different options.
```
$ kvwmap status all
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
$ docker ps -a
```
The parameter -a shows you also the not running container. The command inspect shows you the parameter of a container. Use the name of the container to get detailed information about it.
```
$ docker inspect web
```

## Detailed installation and update description

### Install docker
The installation of docker will be performed in the script kvwmap which has been downloaded with this repository.
The install command of the kvwmap script make use of the install script at get.docker.com
Generally you could have installed docker also as a debian package as described in docker docu [here] (https://docs.docker.com/installation/debian/#installation) But the package must not include the newest version. Therefor it is recommended to use the docker install script from get.docker.com, as we do in the kvwmap install command.

### Update docker
To update the docker Engine run the following command on your host system:
```
$ curl -sSL https://get.docker.com/ | sh
```
You will see the new version of docker client and server after installing with this script. To find the current version of docker engine and client you can allways use the command:
```
$ docker version
```
### Update this repo on your host system
Pull a new version of the repo by typing
```
$ git pull origin master
```
in your directory $USER_DIR/kvwmad-server. This will download all changes in files of this repository, but not the container itself or the images from which the containers has been run. Consider that the downloaded files will have the owner of the user that pull the repo. All files in kvwmap-server should be owned by gisadmin and group gisadmin.
A known problem when download an repo is, that files has been changed without commiting it to the repo.
```
error: Your local changes to the following files would be overwritten by merge:
```
In this case you can find the difference between the local file and the previous version of this file by:
```
$ git diff <file_name_that_has_been_changed>
```
If you whant to commit this change add the file to the stage
```
$ git add <file_name_that_has_been_changed>
```
and commit it with an appropriated message.
```
$ git commit -m "Changed the file: <file_name_that_has_been_changed> because there was a typo inside."
```
Than you should be able to pull the new version from the remote repo.
```
$ git pull origin master
```
When you do so, the remote master will be merged into the local changed repo. Therefor you will be asked to leave a merge message. Do can it leave as it is and quit with Cntl.-X.
But do not forget to push your committed change also to the remote repo, so that outher can also benefit from it.
```
$ git push origin master
```
Therefore you must be a contributor to this repo. Ask the maintainer to become a contributor to this repo.

A new image can be created localy with the build command of docker. But to run the new image the old container must be stopped and the new one created. Therefore the script kvwmap can be used with the following parameters.
To rebuild the kvwmap container run the following command:
```
$ kvwmap rebuild web
```
This will stop and remove only the web container, remove the kvwmap-server image, pull the image kvwmap-server:latest from [dockerhub](https://hub.docker.com/r/pkorduan/kvwmap-server/) and run again the web container as when you start first.
To not build the image, but download the latest from dockerhub you can use the kvwmap script with reload option
```
$ kvwmap reload web
```
To manually rebuild the kvwmap container with another version of mysql or postgres change the version numbers in kvwmap script for the constants MYSQL_IMAGE_VERSION or POSTGRES_IMAGE_VERSION and call the kvwmap script with the parameter rebuild all. You can download the new version manually before restarting the kvwmap container. This will save some downtime of the kvwmap application.
```
$ docker pull mdillon/postgis:<new_version_number>
$ sed -i -e "s|POSTGRESQL_IMAGE_VERSION=9.4|POSTGRESQL_IMAGE_VERSION=<new_version_number>|g" \
$USER_DIR/kvwmap-server/kvwmap
$ kvwmap rebuild all
```
Replace <new_version_number> by the version you want to have for your postgres-container. Remember that this number will be overwritten when you next time pull the repo from master. Checkout this change with:
```
$ cd $USER_DIR/kvwmap-server
$ git checkout kvwmap
```
before you pull the repo and rechange it to the new version back if you want.
