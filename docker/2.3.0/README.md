# Supported tags and respective Dockerfile
	* latest [docker/dockerfile](https://github.com/pkorduan/kvwmap-server/blob/master/docker/Dockerfile)
	* 2.3.0 [docker/2.3.0/Dockerfile](https://github.com/pkorduan/kvwmap-server/blob/master/docker/2.3.0/Dockerfile)
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

### Building Image ###
docker build -t pkorduan/kvwmap-server:2.3.0 .

## Install kvwmap-server
The preferred way to install the `pkorduan/kvwmap-server` image on a blank root server is the command
```
wget -O inithost.sh https://gdi-service.de/public/kvwmap_resources/inithost && \
chmod a+x inithost.sh && \
./inithost.sh
```
The script will clone the kvwmap-server repository from github first and than install
all required components with the included administration script `dcm` (docker container manager).

This Description is not complete. There are some additional steps to configure the services.
Read the inithost.sh and dcm.sh script if you want to install on a running not blank server or to understands the steps to install WebGIS kvwmap in more detail.

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
# 2.3.0
	* remove phpmyadmin and first-run script from this image
# 2.2.9
        * Add apache module remote_ip
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
