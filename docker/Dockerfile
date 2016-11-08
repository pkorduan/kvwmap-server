FROM debian
MAINTAINER Peter Korduan <peter.korduan@gdi-service.de>
LABEL version="1.1.2"

ENV OS_USER="gisadmin" USER_DIR="/home/${OS_USER}" TZ="Europe/Berlin" TERM=xterm

RUN sed -i \
        -e "s|# alias ls=|alias ls=|g" \
        -e "s|# alias ll=|alias ll=|g" \
        -e "s|# alias rm=|alias rm=|g" \
        ~/.bashrc && \
    echo $TZ > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get update && apt-get install -y \
    apt-utils \
    apache2 \
    cgi-mapserver \
    chkconfig \
    cron \
    dialog \
    gdal-bin \
    git \
    htop \
    imagemagick \
    libjson0 \
    less \
    mapserver-bin \
    mysql-client \
    php5 \
    php5-mapscript \
    php5-mysql \
    php5-pgsql \
    php5-curl \
    php5-gd \
    php5-mcrypt \
    postgresql-client \
    sudo \
    unzip \
    vim \
    wget \
    zip \
    ntp

RUN chkconfig cron 1

ADD sources /usr/local/bin

RUN mv /usr/local/bin/liblwgeom-2.1.7.so /usr/lib/liblwgeom-2.1.7.so && \
  chmod +x /usr/local/bin/kvwmap* /usr/local/bin/shp2pgsql /usr/local/bin/pgsql2shp && \
  mv /usr/local/bin/shp2pgsql /usr/bin && \
  mv /usr/local/bin/pgsql2shp /usr/bin

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
    a2enmod authz_groupfile && \
    a2enmod cgi && \
    a2enmod headers && \
    a2enmod rewrite && \
    a2enmod ssl && \
    a2enmod proxy && \
    a2enmod proxy_http && \
    a2enmod proxy_html && \
    a2enmod xml2enc

RUN echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list && \
		apt-get update && apt-get install -y \
		python-certbot-apache -t jessie-backports

#RUN	certbot --apache

#RUN	make-ssl-cert /usr/local/bin/ssl-cert-localhost.cnf /etc/ssl/private/ssl-cert-localhost.crt

ADD https://github.com/phpmyadmin/phpmyadmin/archive/STABLE.zip /tmp/phpmyadmin.zip

WORKDIR /tmp

RUN unzip -q phpmyadmin.zip && \
    rm phpmyadmin.zip && \
    mkdir -p /srv/www/ && \
    mv `ls` /srv/www/phpmyadmin

RUN php /usr/local/bin/composer-setup.php && \
    rm /usr/local/bin/composer-setup.php

RUN groupadd -g 1700 ${OS_USER} && \
  useradd -ms /bin/bash -u 17000 -g 1700 ${OS_USER} && \
  usermod -G ${OS_USER} www-data && \
  chown -R $OS_USER.$OS_USER /srv/www/phpmyadmin && \
  chmod -R g+w /srv/www/phpmyadmin && \
  echo "www-data  ALL=(gisadmin) NOPASSWD: /usr/bin/git" >> /etc/sudoers.d/git

RUN mkdir -p $USER_DIR/.ssh && \
  ssh-keygen -b 2048 -t rsa -f $USER_DIR/.ssh/id_rsa -q -N "" && \
  chown -R $OS_USER.$OS_USER $USER_DIR/.ssh && \
  sed -i "s|#   IdentityFile ~/.ssh/id_rsa|    IdentityFile ~/.ssh/id_rsa|g" /etc/ssh/ssh_config

# force imagemagick to make sharp images
RUN sed -i -e "s|-sDEVICE=pngalpha|-sDEVICE=pnmraw|g" /etc/ImageMagick-6/delegates.xml

USER $OS_USER

RUN git config --global user.name "gisadmin" && \
    git config --global user.email "gisadmin@`hostname`"

USER root

EXPOSE 80
EXPOSE 443

WORKDIR $USER_DIR

CMD /usr/local/bin/kvwmap-start
