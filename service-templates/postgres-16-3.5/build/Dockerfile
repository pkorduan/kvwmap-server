FROM postgis/postgis:16-3.5

RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-16-mysql-fdw \
    postgresql-16-oracle-fdw \
    postgresql-16-pgrouting \
#    postgresql-contrib-15 \
    postgresql-server-dev-16 \
    pgstat \
    postgresql-16-pg-track-settings \
    postgresql-16-cron \
#    postgresql-15-pgaudit \
#    postgresql-15-powa \
#    postgresql-15-pg-qualstats \
#    postgresql-15-pg-stat-kcache \ 
#    postgresql-15-hypopg \
    pgbackrest \
#    alien \
#    apt-utils \
    build-essential \
#    libaio1 \
#    libaio-dev \
    locales \
    locales-all \
    ntp \
    htop \
    wget \
    nano \
    tzdata \
    tree \
    jq \
    postgis \
    git

#######################################
# locale, Zeit
#######################################

#locale
RUN localedef -i de_DE -c -f UTF-8 -A /usr/share/locale/locale.alias de_DE.UTF-8
ENV LANG de_DE.utf8
RUN locale -a

#rm package lists
RUN rm -rf /var/lib/apt/lists/*

#Timezone
RUN rm /etc/localtime
RUN ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime

#######################################
# postgres extensions
#######################################

#pgbackrest settings
RUN mkdir -p /etc/pgbackrest/conf.d
COPY sources/pgbackrest.local.conf /etc/pgbackrest/conf.d
RUN chown -R 999:999 /etc/pgbackrest/conf.d
RUN rm /etc/pgbackrest.conf

#pgmonitor bauen
# https://github.com/CrunchyData/pgmonitor-extension
WORKDIR /etc/
RUN git clone https://github.com/CrunchyData/pgmonitor-extension.git && cd pgmonitor-extension && make install

#######################################
# Konfiguration und Init-Dateien
#######################################

#postgresql default settings
ADD --chown=postgres:postgres sources/postgresql.conf sources/pg_hba.conf /var/lib/postgresql/config/

# initdb scripte
COPY sources/20_pg_cron.sh /docker-entrypoint-initdb.d/
COPY sources/30_init_pgbackrest.sh /docker-entrypoint-initdb.d/
COPY sources/40_pg_track_settings.sh /docker-entrypoint-initdb.d/
COPY sources/50_kvwmapsp.sh /docker-entrypoint-initdb.d/

#aliase
RUN echo "alias ls='ls $LS_OPTIONS' \n alias ll='ls $LS_OPTIONS -l' \n alias rm='rm -i' \n" >> /etc/bash.bashrc

#set work env
WORKDIR /var/lib/postgresql
USER postgres

#env
ENV PGPASSFILE="/var/lib/postgresql/config/.pgpass"
ENV PGSQL_DB="postgres"
ENV PGSQL_USER="postgres"

CMD [ "docker-entrypoint.sh", "postgres", "-c", "config_file=/var/lib/postgresql/config/postgresql.conf" ]
