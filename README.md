# kvwmap-server

A docker container that runs Web-GIS application http://kvwmap.de based on Apache web server
mapservers phpMapScript as well as MySQL database for user and map context and
PostgreSQL database with PostGIS extension for geodata.

**Note:** ``mysql:5.5`` and ``postgis:9.4`` docker images are required to run
a container based on this image ``pkorduan\kvwmap-server``

## Installation
The preferred way to install this image and run the container onto your system
is to pull the kvwmap-server repository from github first and than install
all required components with the included administration script kvwmap.

### Pull kvwmap-server
**Note:** You must be logged in as root and have installed at least the debian
packages git, wget and curl to use git and run the kvwmap script successfully.

```apt-get update && apt-get install -y apt-utils curl git wget```

Clone the ``pkorduan/kvwmap-server`` repository from github in to your user
directory. Assume you have a user directory /home/gisadmin

```USER_DIR="/home/gisadmin"```

```cd USER_DIR```

```git clone https://github.com/pkorduan/kvwmap-server.git```

### Install kvwmap-server
Get and install all the components that uses kvwmap-server.

```USER_DIR/kvwmap-server/kvwmap install```

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

There should be no error messages and 

No you can log in with
user: kvwmap
password: kvmwap

We recommend to change the passwords for mysql, postgres and kvwmap users.

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
