FROM debian:11.9
MAINTAINER Peter Korduan <peter.korduan@gdi-service.de>
LABEL version="2.2.21"

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

RUN sed -i 's|deb.debian.org/debian|archive.debian.org/debian|g' /etc/apt/sources.list && \
    sed -i 's|security.debian.org/debian-security|archive.debian.org/debian-security|g' /etc/apt/sources.list && \
    sed -i '/bullseye-updates/d' /etc/apt/sources.list && \
    echo "Acquire::Check-Valid-Until \"false\";" > /etc/apt/apt.conf.d/99no-check-valid-until

# Basispakete und Build-Werkzeuge (PHP-Pakete aus apt entfernt)
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends \
      apache2 \
      apache2-dev \
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
      zip \
      # Abhängigkeiten für die PHP-Kompilierung aus dem Quellcode
      libxml2-dev \
      libsqlite3-dev \
      libonig-dev \
      libcurl4-openssl-dev \
      libpng-dev \
      libzip-dev \
      libssl-dev \
      libreadline-dev \
      libedit-dev \
      libargon2-dev \
      libsodium-dev \
      pkg-config \
      autoconf \
      bison \
      re2c \
      && rm -rf /var/lib/apt/lists/* && \
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
    service apache2 restart

ADD sources /usr/local/bin
RUN chmod a+x /usr/local/bin/kvwmap-start /usr/local/bin/kvwmap-firstrun /usr/local/bin/compresslog.sh

# Installation von ImageMagick
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

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      libxslt1-dev \
      && rm -rf /var/lib/apt/lists/* && \
      apt-get clean

# ========== PHP 7.4.33 aus dem Quellcode kompilieren + CVE-Patch ==========
WORKDIR /usr/local/src
RUN wget https://museum.php.net/php7/php-7.4.33.tar.gz && \
    tar -xzf php-7.4.33.tar.gz && \
    cd php-7.4.33 && \
    git init && \
    git remote add origin https://github.com/php/php-src.git && \
    git fetch --depth 1 origin PHP-7.4-CVE-2026-109618-109619 && \
    git checkout -f FETCH_HEAD && \
    ./configure \
      --prefix=/usr/local/php \
      --with-apxs2=/usr/bin/apxs2 \
      --with-config-file-path=/usr/local/php/etc \
      --with-config-file-scan-dir=/usr/local/php/etc/conf.d \
      --enable-mbstring \
      --with-curl \
      --with-gd \
      --with-jpeg \
      --with-freetype \
      --with-pgsql \
      --with-pdo-pgsql \
      --with-mysqli \
      --with-pdo-mysql \
      --with-zip \
      --with-libxml \
      --enable-soap \
      --enable-xml \
      --with-xsl \
      --enable-sockets \
      --enable-bcmath \
      --enable-calendar \
      --enable-exif \
      --enable-ftp \
      --enable-sysvmsg \
      --enable-sysvsem \
      --enable-sysvshm \
      --with-openssl \
      --with-zlib \
    && make -j$(nproc) \
    && make install

# Symbolische Links erstellen, damit php direkt aufrufbar ist
RUN ln -sf /usr/local/php/bin/php /usr/bin/php && \
    ln -sf /usr/local/php/bin/php-config /usr/bin/php-config && \
    ln -sf /usr/local/php/bin/phpize /usr/bin/phpize && \
    ln -sf /usr/local/php/bin/pear /usr/bin/pear && \
    ln -sf /usr/local/php/bin/pecl /usr/bin/pecl

# PHP-Modul in Apache laden
RUN echo "LoadModule php7_module /usr/lib/apache2/modules/libphp7.so" >> /etc/apache2/apache2.conf || true

# php.ini erstellen (optional, je nach Bedarf anpassbar)
RUN mkdir -p /usr/local/php/etc/conf.d && \
    cp /usr/local/src/php-7.4.33/php.ini-production /usr/local/php/etc/php.ini
# ========== Ende der PHP-Kompilierung ==========

RUN groupadd -g 1700 ${OS_USER} && \
    useradd -ms /bin/bash -u 17000 -g 1700 ${OS_USER} && \
    usermod -aG ${OS_USER} www-data && \
    usermod -aG www-data ${OS_USER} && \
    echo "www-data  ALL=(gisadmin) NOPASSWD: /usr/bin/git" >> /etc/sudoers.d/git && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    mkdir -p $USER_DIR/.ssh && \
    ssh-keygen -b 2048 -t rsa -f $USER_DIR/.ssh/id_rsa -q -N "" && \
    chown -R $OS_USER.$OS_USER $USER_DIR/.ssh

RUN echo 'umask 0002' >> /home/${OS_USER}/.profile && \
    chown ${OS_USER}:${OS_USER} /home/${OS_USER}/.profile

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

# Installation von MapServer und php-mapscript
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
    # Erweiterungsverzeichnis dynamisch ermitteln (Pfad weicht nach Quellcode-Kompilierung von apt-Version ab)
    EXT_DIR=$(php-config --extension-dir) && \
    cp mapscript/php/php_mapscript.so "$EXT_DIR/" && \
    cp mapserv /usr/lib/cgi-bin

EXPOSE 80
EXPOSE 443

CMD /usr/local/bin/kvwmap-start
