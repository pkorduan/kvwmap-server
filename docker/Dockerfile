FROM debian
MAINTAINER Peter Korduan <peter.korduan@gdi-service.de>
LABEL version="1.0.0"

ENV OS_USER="gisadmin"
ENV USER_DIR="/home/${OS_USER}"

RUN echo "deb http://ftp.de.debian.org/debian/ jessie main contrib non-free" > /etc/apt/sources.list && \
    echo "deb-src http://ftp.de.debian.org/debian/ jessie main contrib non-free" >> /etc/apt/sources.list && \
    sed -i \
        -e "s|# alias ls=|alias ls=|g" \
        -e "s|# alias ll=|alias ll=|g" \
        -e "s|# alias rm=|alias rm=|g" \
        ~/.bashrc

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get update && apt-get install -y \
    apt-utils \
    apache2 \
    cgi-mapserver \
    dialog \
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
    postgresql-client \
    sudo \
    unzip \
    vim \
    wget \
    zip \
    ntp

ADD sources /usr/local/bin

RUN chmod +x /usr/local/bin/kvwmap* /usr/local/bin/shp2pgsql /usr/local/bin/pgsql2shp

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
    a2enmod authz_groupfile && \
    a2enmod cgi && \
    a2enmod rewrite && \
    a2enmod ssl && \
    make-ssl-cert /usr/local/bin/ssl-cert-localhost.cnf /etc/ssl/private/ssl-cert-localhost.crt

ADD https://github.com/phpmyadmin/phpmyadmin/archive/STABLE.zip /tmp/phpmyadmin.zip

WORKDIR /tmp

RUN unzip -q phpmyadmin.zip && \
    rm phpmyadmin.zip && \
    mkdir -p /srv/www/ && \
    mv `ls` /srv/www/phpmyadmin

RUN useradd -ms /bin/bash ${OS_USER} && \
  usermod -G ${OS_USER} www-data && \
  chown -R $OS_USER.$OS_USER /srv/www/phpmyadmin && \
  mkdir -p $USER_DIR/.ssh && \
  ssh-keygen -b 2048 -t rsa -f $USER_DIR/.ssh/id_rsa -q -N "" && \
  chown -R $OS_USER.$OS_USER $USER_DIR/.ssh && \
  sed -i "s|#   IdentityFile ~/.ssh/id_rsa|    IdentityFile ~/.ssh/id_rsa|g" /etc/ssh/ssh_config && \
  echo "www-data  ALL=(gisadmin) NOPASSWD: /usr/bin/git" >> /etc/sudoers.d/git

RUN sed -i "s|<2397>|#<2397>|g" /usr/share/proj/epsg && \
sed -i "s|<2398>|#<2398>|g" /usr/share/proj/epsg && \
sed -i "s|<2399>|#<2399>|g" /usr/share/proj/epsg && \
sed -i "1s|^|# ETRS89 / UTM zone 33N mit fuehrenden 33\n<35833> +proj=tmerc +lat_0=0 +towgs84=0,0,0 +lon_0=15 +k=0.9996 +x_0=33500000 +y_0=0 +ellps=GRS80 +units=m +no_defs <>\n|" /usr/share/proj/epsg && \
sed -i "1s|^|# ETRS89 / UTM zone 33N (zE-N)\n<5650> +proj=tmerc +lat_0=0 +towgs84=0,0,0,0,0,0,0 +lon_0=15 +k=0.9996 +x_0=33500000 +y_0=0 +ellps=GRS80 +units=m +no_defs <>\n|" /usr/share/proj/epsg && \
sed -i "1s|^|# ETRS89 / UTM zone 33N mit fuehrenden 3\n<325833> +proj=tmerc +lat_0=0 +towgs84=0,0,0 +lon_0=15 +k=0.9996 +x_0=3500000 +y_0=0 +ellps=GRS80 +units=m +no_defs <>\n|" /usr/share/proj/epsg && \
sed -i "1s|^|# ETRS89 / LCC Germany (N-E)\n<4839> +proj=lcc +lat_1=48.66666666666666 +lat_2=53.66666666666666 +lat_0=51 +lon_0=10.5 +x_0=0 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs <>\n|" /usr/share/proj/epsg && \
sed -i "1s|^|# Pulkovo 1942(83) / 3-degree Gauss-Kruger zone 5\n<2399> +proj=tmerc +lat_0=0 +lon_0=15 +k=1 +x_0=5500000 +y_0=0 +ellps=krass +towgs84=24,-123,-94,0.02,-0.25,-0.13,1.1 +units=m +no_defs  <>\n|" /usr/share/proj/epsg && \
sed -i "1s|^|# Pulkovo 1942(83) / 3-degree Gauss-Kruger zone 4\n<2398> +proj=tmerc +lat_0=0 +lon_0=12 +k=1 +x_0=4500000 +y_0=0 +ellps=krass +towgs84=24,-123,-94,0.02,-0.25,-0.13,1.1 +units=m +no_defs  <>\n|" /usr/share/proj/epsg && \
sed -i "1s|^|# Pulkovo 1942(83) / 3-degree Gauss-Kruger zone 3\n<2397> +proj=tmerc +lat_0=0 +lon_0=9  +k=1 +x_0=3500000 +y_0=0 +ellps=krass +towgs84=24,-123,-94,0.02,-0.25,-0.13,1.1 +units=m +no_defs  <>\n|" /usr/share/proj/epsg

EXPOSE 80
EXPOSE 443

WORKDIR $USER_DIR

CMD /usr/local/bin/kvwmap-start
