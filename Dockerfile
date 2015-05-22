FROM debian
MAINTAINER Peter Korduan <peter.korduan@gdi-service.de>

# bash für root anpassen
RUN grep -q -F 'alias ll=' /etc/profile || echo "alias ll='ls -l'" >> /etc/profile
RUN grep -q -F 'alias rm=' /etc/profile || echo "alias rm='rm -i'" >> /etc/profile    


RUN apt-get update
RUN apt-get install -y apt-utils \
  apache2 \
  php5 \
  cgi-mapserver \
  mapserver-bin \
  php5-mapscript

EXPOSE 80
EXPOSE 443

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
