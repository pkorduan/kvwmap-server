FROM debian
MAINTAINER Peter Korduan <peter.korduan@gdi-service.de>
LABEL version="latest"

ARG OS_USER="gisadmin"
ARG USER_DIR="/home/${OS_USER}"
ARG TZ="Europe/Berlin"

ENV OS_USER=$OS_USER USER_DIR=$USER_DIR TZ=$TZ TERM=xterm

RUN sed -i \
        -e "s|# alias ls=|alias ls=|g" \
        -e "s|# alias ll=|alias ll=|g" \
        -e "s|# alias rm=|alias rm=|g" \
        ~/.bashrc && \
    echo $TZ > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
    apt-utils \
    apache2 \
    cgi-mapserver \
    chkconfig \
