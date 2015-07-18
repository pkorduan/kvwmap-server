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
**Note:** You must have a installed at least the debian packages git, wget and
curl to use git and run the kvwmap script successfully.

```apt-get update && apt-get install -y apt-utils curl git wget```

Clone the ``pkorduan/kvwmap-server`` repository from github in to your user
directory.

```cd ~```

```git clone https://github.com/pkorduan/kvwmap-server.git```

### Install kvwmap-server
Get and install all the components that uses kvwmap-server.
```kvwmap-server/kvwmap install```

### Start kvwmap-server
Start the containers with volumes and link it together.

```kvwmap start```

### Install kvwmap web application
Open a browser and call the kvwmap install script with the url of your host.

http://yourserver/kvmwmap/install.php

No you can log in with
user: kvwmap
password: kvmwap

We recommend to change the passwords for mysql, postgres and kvwmap users.

## Detailed description

Is comming soon.
