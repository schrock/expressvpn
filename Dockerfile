ARG DISTRIBUTION

FROM debian:${DISTRIBUTION}-slim

ENV CODE="code"
ENV SERVER="smart"
ENV HEALTHCHECK=""
ENV BEARER=""
ENV NETWORK="on"
ENV PROTOCOL="lightway_udp"
ENV CIPHER="chacha20"

ENV SOCKS="off"
ENV SOCKS_LOGS="true"
ENV SOCKS_AUTH_ONCE="false"
ENV SOCKS_USER=""
ENV SOCKS_PASS=""
ENV SOCKS_IP="0.0.0.0"
ENV SOCKS_PORT="1080"
ENV SOCKS_WHITELIST=""

ARG NUM
ARG PLATFORM
ARG TARGETPLATFORM

COPY files/ /expressvpn/

RUN apt update && apt install -y --no-install-recommends \
    expect curl ca-certificates iproute2 wget jq iptables iputils-ping net-tools build-essential git

RUN git clone https://github.com/rofl0r/microsocks.git && cd microsocks && make && \
    cp /microsocks/microsocks /usr/local/bin/microsocks && \
    rm -rf /microsocks

RUN if [ "${TARGETPLATFORM}" = "linux/arm64" ]; then \
    dpkg --add-architecture armhf \
    && apt update && apt install -y --no-install-recommends \
    libc6:armhf libstdc++6:armhf patchelf \
    && ln -sf /usr/lib/arm-linux-gnueabihf/ld-linux-armhf.so.3  /lib/ld-linux-armhf.so.3 \
    && ln -sf /usr/lib/arm-linux-gnueabihf /lib/arm-linux-gnueabihf; \
    fi

RUN wget -q https://www.expressvpn.works/clients/linux/expressvpn_${NUM}-1_${PLATFORM}.deb -O /expressvpn/expressvpn_${NUM}-1_${PLATFORM}.deb \
    && dpkg -i /expressvpn/expressvpn_${NUM}-1_${PLATFORM}.deb \
    && rm -rf /expressvpn/*.deb

RUN if [ "${TARGETPLATFORM}" = "linux/arm64" ]; then \
    patchelf --set-interpreter /lib/ld-linux-armhf.so.3 /usr/bin/expressvpn \
    && patchelf --set-interpreter /lib/ld-linux-armhf.so.3 /usr/bin/expressvpn-browser-helper; \
    fi

RUN apt purge --autoremove -y wget build-essential git \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/log/*.log

HEALTHCHECK --start-period=30s --interval=5m --retries=1 CMD bash /expressvpn/healthcheck.sh

ENTRYPOINT ["/bin/bash", "/expressvpn/start.sh"]
