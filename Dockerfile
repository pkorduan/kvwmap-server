FROM debian
MAINTAINER Peter Korduan <peter.korduan@gdi-service.de>

RUN echo "deb http://ftp.de.debian.org jessie main" > /etc/apt/sources.list

RUN echo "deb http://ftp.de.debian.org/debian/ jessie main contrib non-free" > /etc/apt/sources.list
RUN echo "deb-src http://ftp.de.debian.org/debian/ jessie main contrib non-free" >> /etc/apt/sources.list
RUN apt-get update && apt-get install -y apt-utils \
  less \
  apache2 \
  php5 \
  cgi-mapserver \
  mapserver-bin \
  php5-mapscript

EXPOSE 80
EXPOSE 443

ENV OS_USER="gisadmin"
ENV USER_DIR="/home/${OS_USER}"

# bash für root anpassen
RUN grep -q -F 'alias ll=' /etc/profile || echo "alias ll='ls -l'" >> /etc/profile
RUN grep -q -F 'alias rm=' /etc/profile || echo "alias rm='rm -i'" >> /etc/profile    

RUN useradd -ms /bin/bash ${OS_USER} && \
  sed -i "s/#alias ll='ls/alias ll='ls/g" ${USER_DIR}/.bashrc && \
  sed -i "s/alias rm='rm -i'/# alias rm='rm -i'/g" ${USER_DIR}/.bashrc && \
  chown -R ${OS_USER}.${OS_USER} ${USER_DIR}
  
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
