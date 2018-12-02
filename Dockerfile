#FROM ubuntu:xenial
FROM ubuntu:16.04
MAINTAINER renbuar
ENV DEBIAN_FRONTEND noninteractive
ENV DEBIAN_FRONTEND teletype

RUN ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime

RUN apt-get update && apt-get install -y unixodbc libgsf-1-114 libglib2.0-dev t1utils \
         cabextract imagemagick libusb-1.0-0 libc6-i386 mc make apt-utils udev


#RUN apt-get install -y apt-utils
# make the "en_US.UTF-8" locale so postgres will be utf-8 enabled by default
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
        && localedef -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8
ENV LANG ru_RU.utf8


# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.10
RUN set -x \
        && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
        && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
        && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
        && export GNUPGHOME="$(mktemp -d)" \
        && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
        && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
        && rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc \
        && chmod +x /usr/local/bin/gosu \
        && gosu nobody true
#&& apt-get purge -y --auto-remove ca-certificates wget


ENV SERVER_1C_VERSION 8.3.14-1373
ENV SERVER_1C_ARCH amd64
ENV DIST_SERVER_1C ./dist/
COPY 1c-enterprise83-common_${SERVER_1C_VERSION}_${SERVER_1C_ARCH}.deb /tmp
COPY 1c-enterprise83-server_${SERVER_1C_VERSION}_${SERVER_1C_ARCH}.deb /tmp
COPY fonts-ttf-ms_1.0-eter4ubuntu_all.deb /tmp


RUN if [ ! -f /tmp/1c-enterprise83-common_${SERVER_1C_VERSION}_${SERVER_1C_ARCH}.deb ]; then \
    echo File 1c-enterprise83-common_${SERVER_1C_VERSION}_${SERVER_1C_ARCH}.deb does not exist.; \
    echo "env DIST_SERVER_1C setted incorrectly. See README.md file."; \
    exit 1; fi

RUN if [ ! -f /tmp/1c-enterprise83-server_${SERVER_1C_VERSION}_${SERVER_1C_ARCH}.deb ]; then \
    echo File 1c-enterprise83-server_${SERVER_1C_VERSION}_${SERVER_1C_ARCH}.deb does not exist.; \
    echo "env DIST_SERVER_1C setted incorrectly. See README.md file."; \
    exit 1; fi

RUN if [ ! -f /tmp/fonts-ttf-ms_1.0-eter4ubuntu_all.deb ]; then \
    echo File fonts-ttf-ms_1.0-eter4ubuntu_all.deb does not exist.; \
    echo "env DIST_SERVER_1C setted incorrectly. See README.md file."; \
    exit 1; fi



RUN dpkg -i /tmp/1c-enterprise83-common_${SERVER_1C_VERSION}_${SERVER_1C_ARCH}.deb \
            /tmp/1c-enterprise83-server_${SERVER_1C_VERSION}_${SERVER_1C_ARCH}.deb \
            /tmp/fonts-ttf-ms_1.0-eter4ubuntu_all.deb

RUN rm /tmp/*

RUN mkdir -p /home/usr1cv8/.1cv8/1C/1cv8/conf/
COPY logcfg.xml /home/usr1cv8/.1cv8/1C/1cv8/conf/
RUN chown -R usr1cv8:grp1cv8 /opt/1C
RUN mkdir -p /home/usr1cv8/dumps/
RUN mkdir -p /home/usr1cv8/log/
RUN chown -R usr1cv8:grp1cv8 /home/usr1cv8/
RUN echo 'usr1cv8 soft core unlimited' | tee -a /etc/security/limits.conf
RUN echo 'usr1cv8 hard core unlimited' | tee -a /etc/security/limits.conf
RUN echo 'kernel.core_pattern=/home/usr1cv8/dumps/core.%e.%p ' | tee -a /etc/sysctl.conf
RUN sysctl -p 

#VOLUME /home/usr1cv8/

COPY haspd-modules_7.60-eter1ubuntu_amd64.deb /tmp
COPY haspd_7.60-eter1ubuntu_amd64.deb /tmp

RUN if [ ! -f /tmp/haspd-modules_7.60-eter1ubuntu_amd64.deb ]; then \
    echo File haspd-modules_7.60-eter1ubuntu_amd64.deb does not exist.; \
    echo "env DIST_SERVER_1C setted incorrectly. See README.md file."; \
    exit 1; fi
RUN if [ ! -f /tmp/haspd_7.60-eter1ubuntu_amd64.deb ]; then \
    echo File haspd_7.60-eter1ubuntu_amd64.deb does not exist.; \
    echo "env DIST_SERVER_1C setted incorrectly. See README.md file."; \
    exit 1; fi


RUN dpkg -i /tmp/haspd-modules_7.60-eter1ubuntu_amd64.deb \
            /tmp/haspd_7.60-eter1ubuntu_amd64.deb

RUN rm /tmp/*

#COPY docker-entrypoint.sh /
#ENTRYPOINT ["/docker-entrypoint.sh"]

##ENTRYPOINT  /etc/init.d/haspd start && /opt/1C/v8.3/x86_64/ragent && /bin/bash
ENTRYPOINT  /etc/init.d/haspd start && gosu usr1cv8 /opt/1C/v8.3/x86_64/ragent
#ENTRYPOINT /etc/init.d/haspd start && gosu usr1cv8 /opt/1C/v8.3/x86_64/ragent /port 2540 /regport 2541 /range 2560:2591

#ENTRYPOINT  /etc/init.d/haspd start && gosu usr1cv8 /opt/1C/v8.3/x86_64/ibsrv --address=any --port=8080


EXPOSE 1540-1541 1560-1591 475 1947 8080
#EXPOSE 2540-2541 2560-2591 475 1947 8080

