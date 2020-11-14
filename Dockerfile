FROM alpine:latest

ENV PATH=/usr/local/bin:/usr/local/sbin:$PATH
ENV MOSQUITTO_VERSION=1.6.12
ENV LIBWEBSOCKETS_VERSION=v3.2-stable
ENV TZ=Europe/Rome
ENV PUID=1000

RUN adduser -S -H -h /var/empty -s /sbin/nologin --uid ${PUID} -D -G users --gecos mosquitto mosquitto

COPY entrypoint.sh /usr/bin/

RUN apk --no-cache add --virtual buildDeps git cmake build-base util-linux-dev openssl-dev c-ares-dev; \
    chmod +x /usr/bin/entrypoint.sh && \
    git clone -b ${LIBWEBSOCKETS_VERSION} https://github.com/warmcat/libwebsockets && \
    cd libwebsockets && \
    cmake . \
      -DCMAKE_BUILD_TYPE=MinSizeRel \
      -DLWS_IPV6=ON \
      -DLWS_WITHOUT_CLIENT=ON \
      -DLWS_WITHOUT_TESTAPPS=ON \
      -DLWS_WITHOUT_EXTENSIONS=ON \
      -DLWS_WITHOUT_BUILTIN_GETIFADDRS=ON \
      -DLWS_WITH_ZIP_FOPS=OFF \
      -DLWS_WITH_ZLIB=OFF \
      -DLWS_WITH_SHARED=OFF && \
    make -j "$(nproc)" && \
    rm -rf /root/.cmake && \
    cd .. && \
    wget http://mosquitto.org/files/source/mosquitto-${MOSQUITTO_VERSION}.tar.gz && \
    tar xzfv mosquitto-${MOSQUITTO_VERSION}.tar.gz && \
    mv mosquitto-${MOSQUITTO_VERSION} mosquitto && \
    rm mosquitto-${MOSQUITTO_VERSION}.tar.gz && \
    cd mosquitto && \
    make -j "$(nproc)" \
      CFLAGS="-Wall -O2 -I/libwebsockets/include" \
      LDFLAGS="-L/libwebsockets/lib" \
      WITH_SRV=yes \
      WITH_STRIP=yes \
      WITH_ADNS=no \
      WITH_DOCS=no \
      WITH_MEMORY_TRACKING=no \
      WITH_TLS_PSK=no \
      WITH_WEBSOCKETS=yes \
    binary && \
    install -s -m755 client/mosquitto_pub /usr/bin/mosquitto_pub && \
    install -s -m755 client/mosquitto_rr /usr/bin/mosquitto_rr && \
    install -s -m755 client/mosquitto_sub /usr/bin/mosquitto_sub && \
    install -s -m644 lib/libmosquitto.so.1 /usr/lib/libmosquitto.so.1 && \
    ln -sf /usr/lib/libmosquitto.so.1 /usr/lib/libmosquitto.so && \
    install -s -m755 src/mosquitto /usr/sbin/mosquitto && \
    install -s -m755 src/mosquitto_passwd /usr/bin/mosquitto_passwd && \
    cd / && rm -rf mosquitto && \
    rm -rf libwebsockets && \
    apk --no-cache add tzdata && \
    apk del buildDeps && rm -rf /var/cache/apk/*

ADD mosquitto.conf /etc/mosquitto/mosquitto.conf
RUN touch /etc/mosquitto/passwd

EXPOSE 1883 9001

VOLUME ["/etc/mosquitto"]

ENTRYPOINT ["entrypoint.sh"]
CMD ["/usr/sbin/mosquitto", "-c", "/etc/mosquitto/mosquitto.conf"]
