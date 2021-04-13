FROM debian:9.0 as system

# built-in packages
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends --allow-unauthenticated \
        supervisor curl rxvt-unicode-ml ca-certificates \
        xvfb x11vnc fvwm locales \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    && localedef -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8
ENV LANG ru_RU.UTF-8

# Tini to fix subreap.
ARG TINI_VERSION=v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /bin/tini
RUN chmod +x /bin/tini

# Install 1C && EDT.
FROM system as system_1C

ARG ONEC_USERNAME
ARG ONEC_PASSWORD
ARG ONEC_VERSION
ENV EDT_VERSION=2021.1
ADD http://git.io/oneget.sh /tmp/oneget

RUN cd /tmp \
    && chmod +x oneget \ 
    && ./oneget --user $ONEC_USERNAME --pwd $ONEC_PASSWORD \
        --nicks platform83 --version-filter $ONEC_VERSION --distrib-filter '.*deb64.*tar.gz$' --extract --rename \
    && apt-get update \
    && apt-get install -y --no-install-recommends --allow-unauthenticated ./pack/common-*.deb \
        ./pack/server-*.deb \
        ./pack/client-*.deb \
    && cd /tmp && ./oneget --user $ONEC_USERNAME --pwd $ONEC_PASSWORD get edt:deb@${EDT_VERSION}$ \
    && apt-get install -y --allow-unauthenticated ./downloads/developmenttools10/${EDT_VERSION}/bellsoft*.deb \
    && tar xzf ./downloads/developmenttools10/${EDT_VERSION}/1c_edt*.tar.gz \
    && ./1ce-installer-cli install \
    && echo "alias ring=/opt/1C/1CE/components/1c-enterprise-ring*/ring" > /root/.bashrc \
    && rm -rf /tmp/* \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean -y \
    && mkdir -p /root/.1cv8/1C/1cv8/conf/

# Install OScript.
FROM system_1C as system_OScript_1C
ARG OSCRIPT_VER

ADD https://oscript.io/downloads/latest/x64/onescript-engine_${OSCRIPT_VER}_all.deb /tmp/oscript.deb
RUN apt-get update \
	&& apt-get install -y --no-install-recommends /tmp/oscript.deb \
	&& apt-get install -y --no-install-recommends ca-certificates-mono \
	&& opm install opm \
	&& opm install vanessa-runner \
	&& opm install vanessa-automation \
	&& opm install add \
	&& rm -rf /tmp/* \
	&& rm -rf /var/lib/apt/lists/* \
	&& apt-get clean -y

LABEL maintainer="Sam A. Martyshin"

COPY rootfs /

EXPOSE 5900
WORKDIR /root
ENV RESOLUTION=1440x900

ENTRYPOINT ["/startup.sh"]
