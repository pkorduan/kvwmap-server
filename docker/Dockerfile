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

RUN mv /usr/local/bin/liblwgeom-2.1.7.so /usr/lib/liblwgeom-2.1.7.so && \
		chmod +x /usr/local/bin/kvwmap* /usr/local/bin/shp2pgsql /usr/local/bin/pgsql2shp

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


EXPOSE 80
EXPOSE 443

WORKDIR $USER_DIR

CMD /usr/local/bin/kvwmap-start
