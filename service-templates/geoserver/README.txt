vollständige Beschreibung: https://github.com/kartoza/docker-geoserver#kartoza-docker-geoserver

Die Enviroment-Variabeln 
	GEOSERVER_ADMIN_USER, GEOSERVER_ADMIN_PASSWORD
werden nur für die Initialisierung benötigt (d.h. bei leeren Data_dir)

Nach Erstinstalltion ist das Master-Passwort anzupassen. Wenn ich das richtig verstehe ist das für den Nutzer root, der sich aber im Normalfall nicht einloggen kann.
Unter den Credentials werden aber u.U. Passwörter gespeichert.

Log-Dateien:
Die Log-Dateien von Tomcat werden in das Volume Verzeichnis logs geschrieben.
Die Applikation geoserver schreibt zusätzlich noch ein log in ${data_dir}/logs/geoserver.log

Nach der Installation
	einloggen
	irgendwas ändern und sichern
	links auf Dienste getestet werden

Sind die Links in den Capabilities korrekt?

nginx.conf beachten!
