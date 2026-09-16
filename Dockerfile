FROM webdevops/php-apache:8.4

# Adjust LimitRequestLine and
# update and install dependencies
RUN echo "LimitRequestLine 12000" > /opt/docker/etc/httpd/conf.d/limits.conf \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        git \
        gphoto2 \
        libimage-exiftool-perl \
        rsync \
        udisks2 \
        python3 \
        ca-certificates \
        curl \
        gnupg \
        nodejs \
        usbutils \
        sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy files
WORKDIR /app
COPY . .

RUN chown -R application:application /app

# USB camera device nodes are root-only (0600); grant read/write to everyone right before each
# capture instead of running gphoto2/cameracontrol.py as root, so output files stay owned by 'application'
RUN printf '#!/bin/sh\nchmod 666 /dev/bus/usb/*/* 2>/dev/null || true\n' > /usr/local/bin/fix-camera-perms.sh \
    && chmod 0755 /usr/local/bin/fix-camera-perms.sh \
    && echo 'application ALL=(root) NOPASSWD: /usr/local/bin/fix-camera-perms.sh' > /etc/sudoers.d/photobooth-camera \
    && chmod 0440 /etc/sudoers.d/photobooth-camera

# switch to application user
USER application

# Install and build
RUN git config --global --add safe.directory /app \
    && git submodule update --init \
    && npm install \
    && npm run build
