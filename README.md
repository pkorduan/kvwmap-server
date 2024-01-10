# kvwmap-server
This repository include utility files to support installation process of kvwmap web gis application and provide some script around data management for kvwmap.

See also Docker image https://hub.docker.com/r/pkorduan/kvwmap-server/

Read more in subdirectory docker for spezific version information.

## kvwmap-server installieren
Um den kvwmap-server auf einem neuen System zu installieren, kann ./bin/inithost.sh verwendet werden. Dabei werden notwendige
* Packete
* Systemuser und -gruppen
* Umgebung
* Hostname
* kvwmap-Instanz

eingerichtet. Da das Script Änderungen am Hostsystem vornimmt, wird nicht empfohlen es auf existierenden Systemen auszuführen.
Das Script nimmt eine Config-Datei mit Parametern entgegen, so dass es ohne Prompts durchläuft. Die Parameter (URL, Hostname) müssen vor dem Start angepasst werden.

```
# inithost laden
wget https://raw.githubusercontent.com/pkorduan/kvwmap-server/develop/bin/inithost.sh
chmod +x inithost.sh
# Config laden, anpassen
wget -O kvwmap.config https://raw.githubusercontent.com/pkorduan/kvwmap-server/develop/bin/kvwmapbuild.config
# kvwmap einrichten
./inithost.sh -a install -c kvwmap.config 
```
