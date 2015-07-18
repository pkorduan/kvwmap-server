# kvwmap-server

This repository include all files to install and run the docker image pkorduan/kvwmap-server.

The kvwmap-server contain a the Web-GIS application kvwmap from git repo ```srahn/kvwmap```
an Apache web server, Mapservers phpMapScript as well as a MySQL database for user and
map context and PostgreSQL database with PostGIS extension for geodata.

## Installation
The preferred way to install the `pkorduan/kvwmap-server` image and run the container onto
your system is to pull the kvwmap-server repository from github first and than install
all required components with the included administration script `kvwmap`.

### Pull kvwmap-server
**Note:** You must be logged in as root and have installed at least the debian
packages git, wget and curl to use git and run the kvwmap script successfully.

```apt-get update && apt-get install -y apt-utils curl git wget```

Clone the ``pkorduan/kvwmap-server`` repository from github in to your user
directory. Assume you have a user directory /home/gisadmin

```USER_DIR=/home/gisadmin```

```cd USER_DIR```

```git clone https://github.com/pkorduan/kvwmap-server.git```

### Install kvwmap-server
Get and install all the components that uses kvwmap-server.

```kvwmap-server/kvwmap install```

This scrpit should ended up with the message: Successfully built

### Start kvwmap-server
Start the containers with volumes and link it together. You will be asked to
choose passwords for the MySQL root and PostgreSQL postgres super user.

```kvwmap start```

After this step the container named web, pgsql-server and mysql-server shoud be
set up and run. The output of ```docker ps -a``` is shown.

### Install kvwmap web application
Open a browser and call the kvwmap install script with the url of your host.

http://yourserver/kvmwmap/install.php

There should be no error messages and a hint that you now can login with

user: kvwmap and password: kvmwap

Ignore the Warning: fclose(): 5 is not a valid stream resource in /var/www/apps/kvwmap/class/log.php on line 106

We recommend to change the passwords for mysql, postgres and kvwmap users
after the initial installation. Further configuration settings can be performed
in config.php. See the kvwmap documentation for more information at:
http://kvwmap.de

### Unistall kvwmap-server
Stopp all container and remove images with the kvwmap script:

```kvwmap stop```

```kvwmap clan```

Remove the volumes for the web application kvwmap. Be sure not to remove other
files:

```rm -R /var/www```

Remove the files for kvwmap-server from your user directory:

```cd USER_DIR```

```rm -R db etc kvwmap-server www```

## Detailed installation description

Is comming soon.
