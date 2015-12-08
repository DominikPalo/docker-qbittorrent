FROM debian:jessie

MAINTAINER Werner Beroux <werner@beroux.com>

RUN echo "Install dependencies" \
    && apt-get update \
    && apt-get install -y \
         cmake \
         curl \
         g++ \
         libboost-system-dev \
         libssl-dev \
         pkg-config \
         libqt4-dev \
         qtbase5-dev \

         libboost-system1.55.0 \
         libc6 \
         libgcc1 \
         libqt4-network \
         libqt5network5 \
         libqt5widgets5 \
         libqtcore4 \
         libstdc++6 \
         zlib1g \
    && echo "Download qBittorrent source code" \
    && LIBTORRENT_RASTERBAR_URL=$(curl -L http://www.qbittorrent.org/download.php | grep -Eo 'https?://[^"]*libtorrent[^"]*\.tar\.gz[^"]*' | head -n1) \
    && QBITTORRENT_URL=$(curl -L http://www.qbittorrent.org/download.php | grep -Eo 'https?://[^"]*qbittorrent[^"]*\.tar\.gz[^"]*' | head -n1) \
    && mkdir -p /tmp/libtorrent-rasterbar \
    && mkdir -p /tmp/qbittorrent \
    && curl -L $LIBTORRENT_RASTERBAR_URL | tar xzC /tmp/libtorrent-rasterbar --strip-components=1 \
    && curl -L $QBITTORRENT_URL | tar xzC /tmp/qbittorrent --strip-components=1 \

    && echo "Build and install" \
    && cd /tmp/libtorrent-rasterbar \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make install \

    && cd /tmp/qbittorrent \
    && ./configure --disable-gui \
    && make install \

    && echo "Clean-up" \
    && apt-get purge --auto-remove -y \
         cmake \
         curl \
         g++ \
         libboost-system-dev \
         libssl-dev \
         pkg-config \
         libqt4-dev \
         qtbase5-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \

    && echo "Create symbolic links to simplify mounting" \
    && useradd --system --uid 520 -m --shell /usr/sbin/nologin qbittorrent \

    && mkdir -p /home/qbittorrent/.config/qBittorrent \
    && chown qbittorrent:qbittorrent /home/qbittorrent/.config/qBittorrent \
    && ln -s /home/qbittorrent/.config/qBittorrent /config \

    && mkdir -p /home/qbittorrent/.local/share/data/qBittorrent \
    && chown qbittorrent:qbittorrent /home/qbittorrent/.local/share/data/qBittorrent \
    && ln -s /home/qbittorrent/.local/share/data/qBittorrent /torrents \

    && mkdir /downloads \
    && chown qbittorrent:qbittorrent /downloads

# Default configuration file.
ADD qBittorrent.conf /default/qBittorrent.conf
ADD entrypoint.sh /

VOLUME /config
VOLUME /torrents
VOLUME /downloads

EXPOSE 8080
EXPOSE 6881

USER qbittorrent

ENTRYPOINT ["/entrypoint.sh"]
CMD ["qbittorrent-nox"]
