FROM debian:jessie
MAINTAINER Peter Korduan <peter.korduan@gdi-service.de>
LABEL version="latest"

ARG OS_USER="gisadmin"
ARG USER_DIR="/home/${OS_USER}"
ARG TZ="Europe/Berlin"

ENV OS_USER=$OS_USER USER_DIR=$USER_DIR TZ=$TZ TERM=xterm

RUN sed -i \
        -e "s|# export LS_OPTIONS=|export LS_OPTIONS=|g" \
        -e "s|# alias ls=|alias ls=|g" \
        -e "s|# alias ll=|alias ll=|g" \
        -e "s|# alias rm=|alias rm=|g" \
        ~/.bashrc && \
    echo $TZ > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
    apt-utils \
    apache2 \
    cgi-mapserver \
    chkconfig \
    cron \
    curl \
    dialog \
    gdal-bin \
    git \
    htop \
    imagemagick \
    libjson0 \
    less \
    mapserver-bin \
    mysql-client \
    ntp \
    php5 \
    php5-cli \
    php5-curl \
    php5-gd \
    php5-mapscript \
    php5-mcrypt \
    php5-mysql \
    php5-pgsql \
    postgresql-client \
    sudo \
    unzip \
    vim \
    wget \
    zip

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
    a2enmod expires && \
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

WORKDIR /usr/local/bin

RUN unzip -q phpmyadmin.zip && \
    mv phpmyadmin-STABLE phpmyadmin && \
    rm /usr/local/bin/phpmyadmin.zip && \
    mkdir -p /srv/www/ && \
    mv /usr/local/bin/phpmyadmin /srv/www

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /srv/www/phpmyadmin

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

RUN apt-get update && apt-get install docker.io -y && \
    groupmod -g 999 docker && \
    usermod -a -G docker www-data

USER $OS_USER

RUN composer update

RUN git config --global user.name "gisadmin" && \
    git config --global user.email "gisadmin@`hostname`"

USER root

EXPOSE 80
EXPOSE 443

WORKDIR $USER_DIR

CMD /usr/local/bin/kvwmap-start
