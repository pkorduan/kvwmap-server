FROM debian
MAINTAINER Peter Korduan <peter.korduan@gdi-service.de>
LABEL version="latest"

ARG OS_USER="gisadmin"
ARG USER_DIR="/home/${OS_USER}"

ENV OS_USER=$OS_USER USER_DIR=$USER_DIR TZ="Europe/Berlin" TERM=xterm

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y curl