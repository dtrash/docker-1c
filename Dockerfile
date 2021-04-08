################################################################################
# base system
################################################################################

FROM debian:9.0 as system

# built-in packages
ENV DEBIAN_FRONTEND noninteractive
RUN apt update \
    && apt install -y --no-install-recommends --allow-unauthenticated \
        supervisor rxvt curl ca-certificates \
        xvfb x11vnc fvwm locales \
    && apt autoclean -y \
    && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    && localedef -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8
ENV LANG ru_RU.UTF-8

# tini to fix subreap
ARG TINI_VERSION=v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /bin/tini
RUN chmod +x /bin/tini

# Install 1C.
FROM system

ARG ONEC_USERNAME
ARG ONEC_PASSWORD
ARG ONEC_VERSION
ARG TYPE=platform83

ARG ONEGET_VER=v0.2.3
WORKDIR /tmp

ENV DEBIAN_FRONTEND noninteractive
RUN cd /tmp \
    && curl -L http://git.io/oneget.sh > oneget \
    && chmod +x oneget \ 
    && ./oneget --user $ONEC_USERNAME --pwd $ONEC_PASSWORD \
        --nicks $TYPE --version-filter $ONEC_VERSION --distrib-filter '.*deb64.*tar.gz$' --extract --rename \
    && cd /tmp/pack/ \
    && apt update \
    && apt install -y --allow-unauthenticated ./common-*.deb \
        ./server-*.deb \
        ./client-*.deb \
    && cd /tmp \
    && rm -rf /tmp/pack \
    && mkdir -p /root/.1cv8/1C/1cv8/conf/


LABEL maintainer="dtrash"

COPY rootfs /

EXPOSE 80
WORKDIR /root
ENV RESOLUTION=1440x900

ENTRYPOINT ["/startup.sh"]
