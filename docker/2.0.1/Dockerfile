FROM debian:latest
MAINTAINER Peter Korduan <peter.korduan@gdi-service.de>
LABEL version="2.0.1"

ARG OS_USER="gisadmin"
ARG USER_DIR="/home/${OS_USER}"
ARG TZ=Europe/Berlin

ENV OS_USER=$OS_USER USER_DIR=$USER_DIR TZ=$TZ TERM=linux

RUN sed -i \
        -e "s|# export LS_OPTIONS=|export LS_OPTIONS=|g" \
        -e "s|# alias ls=|alias ls=|g" \
        -e "s|# alias ll=|alias ll=|g" \
        -e "s|# alias l='ls -CF'|alias l='ls -alh --color=yes'|g" \
        -e "s|# alias rm=|alias rm=|g" \
        ~/.bashrc
RUN echo "export PS1=\"\[\e[0m\]\[\e[01;31m\]\u\[\e[0m\]\[\e[00;37m\]@\[\e[0m\]\[\e[01;34m\]\h\[\e[0m\]\[\e[00;37m\]:\[\e[0m\]\[\e[01;37m\]\w\[\e[0m\]\[\e[00;37m\] \\$ \[\e[0m\]\"" >> ~/.bashrc

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime &&\
  echo $TZ > /etc/timezone

RUN echo "deb http://deb.debian.org/debian buster-backports main contrib non-free" > /etc/apt/sources.list.d/backports.list

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
    apt-utils \
    apache2 \
    build-essential \
    cmake \
    cron \
    curl \
    dialog \
    gdal-bin \
    git \
    ghostscript \
    htop \
    libcairo-dev \
    libfcgi-dev \
    libfribidi-dev \
    libgdal-dev \
    libgeos-dev \
    libharfbuzz-dev \
    libjpeg-dev \
    libproj-dev \
    libpq-dev \
    mariadb-client \
    ntp \
    php \
    php-cli \
    php-curl \
    php-dev \
    php-gd \
    php-mysql \
    php-pgsql \
    php-xsl \
    php-zip \
    postgresql-client \
    protobuf-compiler \
    python-cairosvg \
    python3-cairosvg \
    sudo \
    swig \
    unzip \
    vim \
    wget \
    zip

RUN apt-get clean

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

ADD sources /usr/local/bin

# Install mapserver and php-mapscript
WORKDIR /usr/local
RUN wget https://download.osgeo.org/mapserver/mapserver-7.6.1.tar.gz && \
    tar xvfz mapserver-7.6.1.tar.gz && \
    rm mapserver-7.6.1.tar.gz && \
    mkdir mapserver-7.6.1/build && \
    cd mapserver-7.6.1/build && \
    cmake .. -DWITH_PROTOBUFC=0 -DWITH_RSVG=0 -DWITH_CAIRO=1 -DWITH_SVGCAIRO=0 -DWITH_PHP=1 -DWITH_CLIENT_WMS=1 -DWITH_CLIENT_WFS=1 && \
    make && \
    cp mapscript/php/php_mapscript.so /usr/lib/php/20180731/ && \
    cp mapserv /usr/lib/cgi-bin

# Install ImageMagick
WORKDIR /usr/local
RUN git clone https://github.com/ImageMagick/ImageMagick.git && \
    cd ImageMagick && \
    ./configure && \
    make && \
    make install && \
    ln -s /usr/local/bin/convert /usr/bin/convert

# force imagemagick to make sharp images
RUN sed -i -e "s|-sDEVICE=pngalpha|-sDEVICE=pnmraw|g" /usr/local/etc/ImageMagick-7/delegates.xml && \
    echo '<policy domain="coder" rights="read | write" pattern="PDF" />' >> /usr/local/etc/ImageMagick-7/q.xml

# Install phpMyAdmin
WORKDIR /usr/local
RUN wget https://files.phpmyadmin.net/phpMyAdmin/5.0.2/phpMyAdmin-5.0.2-english.tar.gz && \
    tar xvfz phpMyAdmin-5.0.2-english.tar.gz && \
    mv phpMyAdmin-5.0.2-english phpmyadmin && \
    rm phpMyAdmin-5.0.2-english.tar.gz && \
    mkdir -p /srv/www/ && \
    mv phpmyadmin /srv/www
WORKDIR /srv/www/phpmyadmin
RUN groupadd -g 1700 ${OS_USER} && \
    useradd -ms /bin/bash -u 17000 -g 1700 ${OS_USER} && \
    usermod -G ${OS_USER} www-data && \
    chown -R $OS_USER.$OS_USER /srv/www/phpmyadmin && \
    chmod -R g+w /srv/www/phpmyadmin && \
    echo "www-data  ALL=(gisadmin) NOPASSWD: /usr/bin/git" >> /etc/sudoers.d/git

# Install certbot-auto
WORKDIR /usr/local/bin
RUN wget -O /usr/local/bin/certbot-auto https://dl.eff.org/certbot-auto && \
    chmod 0755 /usr/local/bin/certbot-auto
#RUN echo "0 0,12 * * * root python -c 'import random; import time; time.sleep(random.random() * 3600)' && /usr/local/bin/certbot-auto renew" | sudo tee -a /etc/crontab > /dev/null

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN mkdir -p $USER_DIR/.ssh && \
  ssh-keygen -b 2048 -t rsa -f $USER_DIR/.ssh/id_rsa -q -N "" && \
  chown -R $OS_USER.$OS_USER $USER_DIR/.ssh

ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

USER $OS_USER

#RUN composer update

RUN git config --global user.name "Peter Korduan" && \
    git config --global user.email "peter.korduan@gdi-service.de"

USER root

EXPOSE 80
EXPOSE 443

WORKDIR $USER_DIR

CMD /usr/local/bin/kvwmap-start