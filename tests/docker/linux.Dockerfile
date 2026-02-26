FROM debian:bookworm-slim

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        bash ca-certificates curl git grep sed coreutils findutils jq \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsLS get.chezmoi.io | sh -s -- -b /usr/local/bin

WORKDIR /repo
