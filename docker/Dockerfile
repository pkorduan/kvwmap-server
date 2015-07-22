FROM debian
MAINTAINER Peter Korduan <peter.korduan@gdi-service.de>

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
    postgresql-client \
    vim \
    wget \
    zip

ADD sources/config.inc.php /
ADD sources/create_mysql_user.sql /
ADD sources/kvwmap-start /usr/local/bin/
ADD sources/kvwmap-setpghost /usr/local/bin/
ADD sources/kvwmap-firstrun /usr/local/bin/
ADD sources/shp2pgsql /usr/bin/
ADD sources/pgsql2shp /usr/bin/
ADD sources/liblwgeom-2.1.7.so /usr/lib/

RUN chmod +x /usr/local/bin/kvwmap* /usr/bin/shp2pgsql /usr/bin/pgsql2shp

ENV OS_USER="gisadmin"
ENV USER_DIR="/home/${OS_USER}"

RUN useradd -ms /bin/bash ${OS_USER} && \
  usermod -G ${OS_USER} www-data

EXPOSE 80
EXPOSE 443

CMD /usr/local/bin/kvwmap-start
