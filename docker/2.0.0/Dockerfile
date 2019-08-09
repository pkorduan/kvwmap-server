FROM debian:buster
MAINTAINER Peter Korduan <peter.korduan@gdi-service.de>
LABEL version="2.0.0"

ARG OS_USER="gisadmin"
ARG USER_DIR="/home/${OS_USER}"
ARG TZ=Europe/Berlin

ENV OS_USER=$OS_USER USER_DIR=$USER_DIR TZ=$TZ TERM=linux

RUN sed -i \
        -e "s|# export LS_OPTIONS=|export LS_OPTIONS=|g" \
        -e "s|# alias ls=|alias ls=|g" \
        -e "s|# alias ll=|alias ll=|g" \
        -e "s|# alias rm=|alias rm=|g" \
        ~/.bashrc

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime &&\
  echo $TZ > /etc/timezone

RUN echo "deb http://deb.debian.org/debian buster-backports main contrib non-free" > /etc/apt/sources.list.d/backports.list

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
    apt-utils \
    apache2 \
    cgi-mapserver \
    cron \
    curl \
    dialog \
    gdal-bin \
    git \
    htop \
    imagemagick \
    mariadb-client \
    ntp \
    php \
    php-cli \
    php-curl \
    php-gd \
    php-mapscript \
    php-mysql \
    php-pgsql \
    php-xsl \
    postgresql-client \
    sudo \
    unzip \
    vim \
    wget \
    zip

#ADD sources /usr/local/bin

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

RUN wget -O /usr/local/certbot-auto https://dl.eff.org/certbot-auto && \
    chmod a+x /usr/local/certbot-auto

RUN groupadd -g 1700 ${OS_USER} && \
  useradd -ms /bin/bash -u 17000 -g 1700 ${OS_USER} && \
  usermod -G ${OS_USER} www-data && \
  echo "www-data  ALL=(gisadmin) NOPASSWD: /usr/bin/git" >> /etc/sudoers.d/git

RUN mkdir -p $USER_DIR/.ssh && \
  ssh-keygen -b 2048 -t rsa -f $USER_DIR/.ssh/id_rsa -q -N "" && \
  chown -R $OS_USER.$OS_USER $USER_DIR/.ssh

# force imagemagick to make sharp images
RUN sed -i -e "s|-sDEVICE=pngalpha|-sDEVICE=pnmraw|g" /etc/ImageMagick-6/delegates.xml

USER $OS_USER

#RUN composer update

RUN git config --global user.name "gisadmin" && \
    git config --global user.email "gisadmin@`hostname`"

USER root

EXPOSE 80
EXPOSE 443

WORKDIR $USER_DIR

CMD /usr/local/bin/kvwmap-start