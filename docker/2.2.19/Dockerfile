FROM debian:11.9
MAINTAINER Peter Korduan <peter.korduan@gdi-service.de>
LABEL version="2.2.17"

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
      p7zip-full \
      zip && \
   rm -rf /var/lib/apt/lists/* && \
   apt-get clean

RUN echo "deb http://security.debian.org/debian-security bullseye-security main" >> /etc/apt/sources.list \
 && apt-get update \
 && apt-get install -y --only-upgrade \
    curl \
    libcurl3-gnutls \
    libcurl4 \
    libcurl4-gnutls-dev \
    libdb5.3 \
    libgssapi-krb5-2 \
    libk5crypto3 \
    libkrb5-3 \
    libpython3.9-stdlib \
    libxml2 \
    libxml2-dev \
    php7.4 \
    php7.4-cli \
    php7.4-common \
    php7.4-curl \
    php7.4-gd \
    php7.4-json \
    php7.4-mbstring \
    php7.4-mysql \
    php7.4-pgsql \
    php7.4-soap \
    php7.4-sqlite3 \
    php7.4-xml \
    php7.4-zip \
    python3.9 \
    python3.9-minimal \
    wget \
    zlib1g \
    zlib1g-dev



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

ADD sources /usr/local/bin
RUN chmod a+x /usr/local/bin/kvwmap-start /usr/local/bin/kvwmap-firstrun /usr/local/bin/compresslog.sh

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
    usermod -aG ${OS_USER} www-data && \
    usermod -aG www-data ${OS_USER} && \
    echo "www-data  ALL=(gisadmin) NOPASSWD: /usr/bin/git" >> /etc/sudoers.d/git && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    mkdir -p $USER_DIR/.ssh && \
    ssh-keygen -b 2048 -t rsa -f $USER_DIR/.ssh/id_rsa -q -N "" && \
    chown -R $OS_USER.$OS_USER $USER_DIR/.ssh

RUN echo "umask 0002" >> /home/${OS_USER}/.bashrc && \
    chown ${OS_USER}:${OS_USER} /home/${OS_USER}/.bashrc

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

EXPOSE 80
EXPOSE 443

CMD /usr/local/bin/kvwmap-start
