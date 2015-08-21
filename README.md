# kvwmap-server

This repository include all files to install and run a container based on the docker
image [pkorduan/kvwmap-server](https://registry.hub.docker.com/u/pkorduan/kvwmap-server/).

The kvwmap-server contain a the Web-GIS application kvwmap from the git repo [srahn/kvwmap](https://github.com/srahn/kvwmap), an [http://httpd.apache.org/](Apache Web Werver),
[MapServers](http://mapserver.org/) [phpMapScript](http://mapserver.org/mapscript/php/index.html)
as well as a [MySQL](http://www.mysql.com/) database for user and map context and [PostgreSQL](http://www.postgres.org) database with [PostGIS](http://www.postgis.org) extension
for geodata.

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
choose passwords for the MySQL root and PostgreSQL postgres super user.

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

## Detailed installation description

### Install docker
The installation of docker will be performed in the script kvwmap which has been downloaded with this repository.
The install command of the kvwmap script make use of the install script at get.docker.com
Generally you could have installed docker also as a debian package as described in docker docu [here] (https://docs.docker.com/installation/debian/#installation) But the package must not include the newest version. Therefor it is recommended to use the docker install script from get.docker.com, as we do in the kvwmap install command.

### Update docker
To update the docker Engine run the following commands on your host system:
```
$ service docker stop
$ curl -sSL https://get.docker.com/ | sh
$ kvwmap start all
```
To see the new version of docker run
```
$ docker version
```
### Update this repo on your host system
Pull a new version of the repo by typing
```
$ git pull origin master
```
in your directory $USER_DIR/kvwmad-server. This will download all changes in files of this repository, but not the container itself or the images from which the containers has been run. Consider that the downloaded files will have the owner of the user that pull the repo. All files in kvwmap-server should be owned by gisadmin and group gisadmin.
To rebuild the kvwmap container run the following command:
```
$ kvwmap rebuild
```
This will stop and remove the running container, remove the kvwmap-server image, pull the image kvwmap-server:latest from [dockerhub](https://hub.docker.com/r/pkorduan/kvwmap-server/) and run all container as when you start first. The only difference to the start procedure is, that the images for debian, mysql-server and pgsql-server as been pulled allready except when the versions for the images in kvwmap script has been changed. When for example the version of postgis images has been changed to 9.5, a new image will be downloaded with the name mdillon/postgis:9.5 before start of the postgres container.
To manually rebuild the kvwmap container with another version of mysql or postgres change the version numbers in kvwmap script for the constants MYSQL_IMAGE_VERSION or POSTGRES_IMAGE_VERSION before typing the above rebuild command. You also can download the new version manually before restarting the kvwmap container. This will save some downtime of the kvwmap application.
```
$ docker pull mdillon/postgis:<new_version_number>
$ sed -i -e "s|POSTGRESQL_IMAGE_VERSION=9.4|POSTGRESQL_IMAGE_VERSION=<new_version_number>|g" $USER_DIR/kvwmap-server/kvwmap
$ kvwmap rebuild
```
Replace <new_version_number> by the version you want to have for your postgres-container. Remember that this number will be overwritten when you next time pull the repo from master. Checkout this change with:
```
$ cd $USER_DIR/kvwmap-server
$ git checkout kvwmap
```
before you pull the repo and rechange it to the new version back if you want.
