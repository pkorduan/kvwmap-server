FROM debian:13
LABEL maintainer="Peter Korduan <peter.korduan@gdi-service.de>"
LABEL version="2.3.8"

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

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends \
      apache2 \
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
      imagemagick \
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
      libmagickcore-7.q16-10-extra \
      librsvg2-bin \
      mariadb-client \
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
      systemd-timesyncd \
      swig \
      unzip \
      vim \
      wget \
      zip && \
   update-ca-certificates && \
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

ADD sources /usr/local/bin
RUN chmod a+x /usr/local/bin/kvwmap-start /usr/local/bin/kvwmap-firstrun /usr/local/bin/compresslog.sh

# ImageMagick kommt aus Debian (Sicherheitsupdates über trixie-security)
RUN sed -i -e 's#-sDEVICE=pngalpha#-sDEVICE=pnmraw#g' /etc/ImageMagick-7/delegates.xml && \
    sed -i -e 's#rights="none" pattern="PDF"#rights="read | write" pattern="PDF"#' /etc/ImageMagick-7/policy.xml && \
    ln -sf "$(command -v convert || command -v magick)" /usr/local/bin/convert

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

ENV LD_LIBRARY_PATH=/usr/local/lib

USER $OS_USER
WORKDIR $USER_DIR
RUN git config --global user.name "Peter Korduan" && \
    git config --global user.email "peter.korduan@gdi-service.de"

USER root

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends \
      inkscape

# Install mapserver and php-mapscript
WORKDIR /usr/local
RUN wget https://download.osgeo.org/mapserver/mapserver-8.6.6.tar.gz && \
    tar xvfz mapserver-8.6.6.tar.gz && \
    mkdir mapserver-8.6.6/build && \
    cd mapserver-8.6.6/build && \
    cmake .. \
    -DWITH_PROTOBUFC=0 \
    -DWITH_RSVG=1 \
    -DWITH_CAIRO=1 \
    -DWITH_SVGCAIRO=0 \
    -DWITH_PHPNG=1 \
    -DWITH_CLIENT_WMS=1 \
    -DWITH_CLIENT_WFS=1 && \
    make && \
    make install && \
    cp mapserv /usr/lib/cgi-bin

EXPOSE 80
EXPOSE 443

CMD ["/usr/local/bin/kvwmap-start"]
