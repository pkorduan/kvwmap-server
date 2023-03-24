FROM debian:11.3
MAINTAINER Peter Korduan <peter.korduan@gdi-service.de>
LABEL version="2.2.13"

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

#RUN echo "deb http://deb.debian.org/debian buster-backports main contrib non-free" > /etc/apt/sources.list.d/backports.list

#RUN wget -O /etc/apt/trusted.gpg.d/apache2.gpg https://packages.sury.org/apache2/apt.gpg && sh -c 'echo "deb https://packages.sury.org/apache2/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/apache2.list'

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends \
      apache2 \
      apt-utils \
      apt-transport-https \
      build-essential \
      cmake \
      cron \
      curl \
      dialog \
      libfreetype6-dev \
      lsb-release \
      gdal-bin \
      git \
      ghostscript \
      gsfonts \
      htop \
      jq \
      libcairo-dev \
      libfcgi-dev \
      libfribidi-dev \
      libgdal-dev \
      libgeos-dev \
      libharfbuzz-dev \
      libio-socket-ssl-perl \
      libjpeg-dev \
      libnet-ssleay-perl \
      libproj-dev \
      libpq-dev \
      librsvg2-dev \
      mariadb-client \
      ntp \
      openssh-client \
      php \
      php-cli \
      php-curl \
      php-dev \
      php-gd \
      php-mbstring \
      php-mysql \
      php-pgsql \
      php-soap \
      php-sqlite3 \
      php-xsl \
      php-zip \
      postgresql-client \
      protobuf-compiler \
      python3-cairosvg \
      python3-certbot-apache \
      sendemail \
      sudo \
      swig \
      unzip \
      vim \
      wget \
      zip && \
   rm -rf /var/lib/apt/lists/* && \
   apt-get clean

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
    a2enmod authz_groupfile && \
    a2enmod cgi && \
    a2enmod headers && \
    a2enmod rewrite && \
    a2enmod ssl && \
    a2enmod proxy && \
    a2enmod proxy_http && \
    a2enmod proxy_html && \
    a2enmod remoteip && \
    a2enmod xml2enc && \
    phpenmod zip && \
    service apache2 restart

# Install ImageMagick
WORKDIR /usr/local
RUN git clone --branch 6.9.11-60 --depth 1 https://github.com/ImageMagick/ImageMagick6.git && \
    cd ImageMagick6 && \
    ./configure --with-rsvg=yes --with-gs-font-dir=/usr/share/fonts/type1/gsfonts/ --disable-hdri && \
    make && \
    make install && \
    ln -s /usr/local/bin/convert /usr/bin/convert && \
    sed -i -e "s|-sDEVICE=pngalpha|-sDEVICE=pnmraw|g" /usr/local/etc/ImageMagick-6/delegates.xml && \
    echo '<policy domain="coder" rights="read | write" pattern="PDF" />' >> /usr/local/etc/ImageMagick-6/q.xml && \
    ldconfig /usr/local/lib

RUN groupadd -g 1700 ${OS_USER} && \
    useradd -ms /bin/bash -u 17000 -g 1700 ${OS_USER} && \
    usermod -G ${OS_USER} www-data && \
    echo "www-data  ALL=(gisadmin) NOPASSWD: /usr/bin/git" >> /etc/sudoers.d/git && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    mkdir -p $USER_DIR/.ssh && \
    ssh-keygen -b 2048 -t rsa -f $USER_DIR/.ssh/id_rsa -q -N "" && \
    chown -R $OS_USER.$OS_USER $USER_DIR/.ssh

ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

USER $OS_USER
WORKDIR $USER_DIR
RUN git config --global user.name "Peter Korduan" && \
    git config --global user.email "peter.korduan@gdi-service.de"

USER root

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends \
      inkscape

# Install mapserver and php-mapscript
WORKDIR /usr/local
RUN wget https://download.osgeo.org/mapserver/mapserver-7.4.5.tar.gz && \
    tar xvfz mapserver-7.4.5.tar.gz && \
    mkdir mapserver-7.4.5/build && \
    cd mapserver-7.4.5/build && \
    cmake .. \
    -DWITH_PROTOBUFC=0 \
    -DWITH_RSVG=1 \
    -DWITH_CAIRO=1 \
    -DWITH_SVGCAIRO=0 \
    -DWITH_PHP=1 \
    -DWITH_CLIENT_WMS=1 \
    -DWITH_CLIENT_WFS=1 && \
    make && \
    cp mapscript/php/php_mapscript.so /usr/lib/php/20190902/ && \
    cp mapserv /usr/lib/cgi-bin

ADD sources /usr/local/bin
RUN chmod a+x /usr/local/bin/kvwmap-start /usr/local/bin/kvwmap-firstrun /usr/local/bin/compresslog.sh

EXPOSE 80
EXPOSE 443

CMD [ "/usr/local/bin/kvwmap-start" ]
