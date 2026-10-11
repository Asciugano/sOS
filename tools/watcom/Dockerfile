FROM --platform=linux/amd64 ubuntu:22.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget xz-utils ca-certificates make \
    && rm -rf /var/lib/apt/lists/*

# Snapshot Linux di OpenWatcom v2
RUN mkdir -p /opt/watcom \
    && wget -q -O /tmp/ow.tar.xz \
       https://github.com/open-watcom/open-watcom-v2/releases/download/Current-build/ow-snapshot.tar.xz \
    && tar -xf /tmp/ow.tar.xz -C /opt/watcom \
    && rm /tmp/ow.tar.xz

ENV WATCOM=/opt/watcom
ENV PATH=/opt/watcom/binl64:/opt/watcom/binl:$PATH
ENV INCLUDE=/opt/watcom/lh

WORKDIR /src
