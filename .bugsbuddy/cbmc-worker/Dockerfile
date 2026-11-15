FROM diffblue/cbmc@sha256:5289f91abddb700d2e4c614018032d078b15aff297328b1a3ae14f73a53efa28

USER root

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      gcc \
      g++ \
      libc6-dev \
    && rm -rf /var/lib/apt/lists/*

ENV PATH="/usr/local/bin:${PATH}"

COPY entrypoint.sh /usr/local/bin/sabkaproof-cbmc
RUN chmod 0555 /usr/local/bin/sabkaproof-cbmc

WORKDIR /source
