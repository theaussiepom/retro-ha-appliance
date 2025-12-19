FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    kcov \
    make \
    python3 \
    shellcheck \
  && rm -rf /var/lib/apt/lists/*
