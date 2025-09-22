# Jellyfin Pterodactyl Egg Project

This project creates a custom Pterodactyl egg for running Jellyfin media server instances. This allows game server hosting providers and communities to offer Jellyfin as a managed service alongside game servers.

## Project Structure
- `egg-jellyfin.json` - Main Pterodactyl egg configuration
- `docker/` - Custom Docker configuration for Jellyfin
- `scripts/` - Startup and management scripts
- `docs/` - Installation and usage documentation

## Development Guidelines
- Focus on Pterodactyl Panel v1.x compatibility
- Ensure Docker container security and isolation
- Support standard Jellyfin configuration options
- Include proper resource management and monitoring
- Follow Pterodactyl egg best practices for variables and startup commands

## Key Features to Implement
- Automated Jellyfin installation and setup
- Configurable media library paths
- User management integration
- Backup and restore capabilities
- Resource monitoring and limits
- SSL/TLS certificate support