FROM ubuntu:22.04
MAINTAINER Matt Godbolt <matt@godbolt.org>

ARG DEBIAN_FRONTEND=noninteractive
RUN apt update -y -q && apt upgrade -y -q && apt update -y -q && \
    apt -q install -y \
    build-essential \
    curl \
    git \
    libgdbm-dev \
    perl \
    unzip \
    xz-utils \
    zlib1g-dev \
    && \
    cpan Devel::PatchPerl \
    && \
    cd /tmp && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws* \
    && \
    # Remove apt's lists to make the image smaller.
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root
COPY build /root/

WORKDIR /root
