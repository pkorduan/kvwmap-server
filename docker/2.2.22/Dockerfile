FROM debian:11.9
MAINTAINER Peter Korduan <peter.korduan@gdi-service.de>
LABEL version="2.2.22"

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
      ca-certificates \
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
      libxslt1-dev \
      libffi-dev \
      libwebp-dev \
      pkg-config \
      autoconf \
      bison \
      re2c \
      && update-ca-certificates \
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

# ========== PHP 7.4 aus dem Quellcode kompilieren + CVE-Patch ==========
# Branch PHP-7.4-CVE-2026-109618-109619 auf festen Commit gepinnt
# (Fix GHSA-w8hw-w9fx-j79w / CVE-2026-109618 und GHSA-6wmf-4rv5-p3rp / CVE-2026-109619)
ARG PHP_SRC_COMMIT=712e60f9edfd03f0960fc4fc3c2c375f42b90aa2
# Pfade wie bei den Debian-Paketen, damit das gemountete ./php/7.4:/etc/php/7.4
# (php.ini, conf.d, mods-available mit extension=xyz.so) weiter funktioniert.
# Deshalb werden die Extensions auch wie bei Debian als shared gebaut.
WORKDIR /usr/local/src
RUN git init php-src && \
    cd php-src && \
    git remote add origin https://github.com/php/php-src.git && \
    git fetch --depth 1 origin ${PHP_SRC_COMMIT} && \
    git checkout FETCH_HEAD && \
    ./buildconf --force && \
    EXTENSION_DIR=/usr/lib/php/20190902 ./configure \
      --prefix=/usr/local/php \
      --with-apxs2=/usr/bin/apxs2 \
      --with-config-file-path=/etc/php/7.4/apache2 \
      --with-config-file-scan-dir=/etc/php/7.4/apache2/conf.d \
      --disable-cgi \
      --without-pear \
      --with-openssl \
      --with-zlib \
      --with-libxml \
      --enable-opcache \
      --enable-bcmath=shared \
      --enable-calendar=shared \
      --enable-ctype=shared \
      --with-curl=shared \
      --enable-dom=shared \
      --enable-exif=shared \
      --with-ffi=shared \
      --enable-fileinfo=shared \
      --enable-ftp=shared \
      --enable-gd=shared \
      --with-jpeg \
      --with-freetype \
      --with-webp \
      --with-gettext=shared \
      --with-iconv=shared \
      --enable-json=shared \
      --enable-mbstring=shared \
      --enable-mysqlnd=shared \
      --with-mysqli=shared \
      --enable-pdo=shared \
      --with-pdo-mysql=shared \
      --with-pdo-pgsql=shared \
      --with-pdo-sqlite=shared \
      --with-pgsql=shared \
      --enable-phar=shared \
      --enable-posix=shared \
      --with-libedit=shared \
      --enable-shmop=shared \
      --enable-simplexml=shared \
      --enable-soap=shared \
      --enable-sockets=shared \
      --with-sqlite3=shared \
      --enable-sysvmsg=shared \
      --enable-sysvsem=shared \
      --enable-sysvshm=shared \
      --enable-tokenizer=shared \
      --enable-xml=shared \
      --enable-xmlreader=shared \
      --enable-xmlwriter=shared \
      --with-xsl=shared \
      --with-zip=shared \
    && make -j$(nproc) \
    && make install \
    && mkdir -p /etc/php/7.4/mods-available /etc/php/7.4/apache2/conf.d /etc/php/7.4/cli/conf.d \
    && cp php.ini-production /etc/php/7.4/apache2/php.ini \
    && sed -e 's|^memory_limit = .*|memory_limit = -1|' php.ini-production > /etc/php/7.4/cli/php.ini \
    && cd /usr/local/src && rm -rf php-src

# Default-Konfiguration im Debian-Layout (wird durch den Mount ./php/7.4:/etc/php/7.4 überdeckt)
RUN cd /etc/php/7.4 && \
    for e in 10:mysqlnd 10:opcache 10:pdo 15:xml \
             20:bcmath 20:calendar 20:ctype 20:curl 20:dom 20:exif 20:ffi 20:fileinfo 20:ftp 20:gd \
             20:gettext 20:iconv 20:json 20:mbstring 20:mysqli 20:pdo_mysql 20:pdo_pgsql 20:pdo_sqlite \
             20:pgsql 20:phar 20:posix 20:readline 20:shmop 20:simplexml 20:soap 20:sockets 20:sqlite3 \
             20:sysvmsg 20:sysvsem 20:sysvshm 20:tokenizer 20:xmlreader 20:xmlwriter 20:xsl 20:zip; do \
      prio=${e%%:*}; mod=${e#*:}; \
      if [ "$mod" = "opcache" ]; then directive=zend_extension; else directive=extension; fi; \
      printf '; configuration for php %s module\n; priority=%s\n%s=%s.so\n' "$mod" "$prio" "$directive" "$mod" > mods-available/$mod.ini; \
      ln -s /etc/php/7.4/mods-available/$mod.ini apache2/conf.d/$prio-$mod.ini; \
      ln -s /etc/php/7.4/mods-available/$mod.ini cli/conf.d/$prio-$mod.ini; \
    done

# CLI-Wrapper (wie bei Debian eigene php.ini für die CLI) und Links
COPY php/php /usr/bin/php
RUN chmod 755 /usr/bin/php && \
    ln -sf /usr/local/php/bin/php-config /usr/bin/php-config && \
    ln -sf /usr/local/php/bin/phpize /usr/bin/phpize

# PHP-Modul in Apache laden: mod_php ist nicht threadsafe -> mpm_prefork,
# php7.4.conf setzt den Handler für .php-Dateien (wie libapache2-mod-php7.4)
COPY php/php7.4.load php/php7.4.conf /etc/apache2/mods-available/
RUN rm -f /etc/apache2/mods-enabled/php7.* /etc/apache2/mods-available/php7.load && \
    sed -i '/LoadModule php7_module/d' /etc/apache2/apache2.conf && \
    a2dismod mpm_event && \
    a2enmod mpm_prefork && \
    a2enmod php7.4
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
    cp mapserv /usr/lib/cgi-bin && \
    printf '; configuration for php mapscript module\n; priority=20\nextension=php_mapscript.so\n' > /etc/php/7.4/mods-available/mapscript.ini && \
    ln -s /etc/php/7.4/mods-available/mapscript.ini /etc/php/7.4/apache2/conf.d/20-mapscript.ini && \
    ln -s /etc/php/7.4/mods-available/mapscript.ini /etc/php/7.4/cli/conf.d/20-mapscript.ini

EXPOSE 80
EXPOSE 443

CMD /usr/local/bin/kvwmap-start

