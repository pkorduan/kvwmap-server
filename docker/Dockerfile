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
    imagemagick \
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

ENV PHPMYADMIN_VERSION="4.4.10"

RUN mkdir -p /var/www/apps && \
  cd /var/www/apps && \
  wget -O phpMyAdmin.tar.gz http://downloads.sourceforge.net/project/phpmyadmin/phpMyAdmin/${PHPMYADMIN_VERSION}/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.gz && \
  tar xvfz phpMyAdmin.tar.gz && \
  mv /var/www/apps/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages /var/www/apps/phpMyAdmin && \
  rm /var/www/apps/phpMyAdmin.tar.gz

ADD sources/config.inc.php /
ADD sources/create_mysql_user.sql /
ADD sources/kvwmap-start /usr/local/bin/
ADD sources/kvwmap-firstrun /usr/local/bin/
ADD sources/kvwmap.conf /etc/apache2/sites-available/
ADD sources/mapserver.conf /etc/apache2/sites-available/
ADD sources/phpmyadmin.conf /etc/apache2/sites-available/

RUN chmod +x /usr/local/bin/kvwmap*

ENV OS_USER="gisadmin"
ENV USER_DIR="/home/${OS_USER}"

RUN useradd -ms /bin/bash ${OS_USER} && \
  sed -i "s/#alias ll=/alias ll=/g" ${USER_DIR}/.bashrc && \
  sed -i "s/alias rm='rm -i'/# alias rm='rm -i'/g" ${USER_DIR}/.bashrc && \
  usermod -G ${OS_USER} www-data && \
  chown -R ${OS_USER}.${OS_USER} ${USER_DIR}

RUN ln -s /etc/apache2/sites-available/kvwmap.conf /etc/apache2/sites-enabled/kvwmap.conf && \
    ln -s /etc/apache2/sites-available/mapserver.conf /etc/apache2/sites-enabled/mapserver.conf && \
    ln -s /etc/apache2/sites-available/phpmyadmin.conf /etc/apache2/sites-enabled/phpmyadmin.conf

EXPOSE 80
EXPOSE 443

CMD /usr/local/bin/kvwmap-start