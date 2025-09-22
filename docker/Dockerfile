FROM ghcr.io/jellyfin/jellyfin:latest

# Set labels for metadata
LABEL maintainer="Pterodactyl Panel"
LABEL description="Custom Jellyfin Docker image for Pterodactyl Panel"

# Install additional packages for Pterodactyl compatibility
USER root

# Install required packages
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    ca-certificates \
    ffmpeg \
    vainfo \
    && rm -rf /var/lib/apt/lists/*

# Create jellyfin user with proper UID/GID for Pterodactyl
RUN groupmod -g 1000 jellyfin && \
    usermod -u 1000 -g 1000 jellyfin

# Create necessary directories
RUN mkdir -p /home/container/data \
             /home/container/cache \
             /home/container/config \
             /home/container/logs \
             /home/container/media && \
    chown -R jellyfin:jellyfin /home/container

# Set working directory
WORKDIR /home/container

# Switch to jellyfin user
USER jellyfin

# Expose ports
EXPOSE 8096 8920 7359/udp 1900/udp

# Set environment variables
ENV JELLYFIN_DATA_DIR=/home/container/data
ENV JELLYFIN_CONFIG_DIR=/home/container/config
ENV JELLYFIN_LOG_DIR=/home/container/logs
ENV JELLYFIN_CACHE_DIR=/home/container/cache
ENV JELLYFIN_WEB_DIR=/usr/share/jellyfin/web

# Copy custom entrypoint script
COPY --chown=jellyfin:jellyfin entrypoint.sh /home/container/
RUN chmod +x /home/container/entrypoint.sh

ENTRYPOINT ["/home/container/entrypoint.sh"]