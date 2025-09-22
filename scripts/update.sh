#!/bin/bash

# Jellyfin Update Script
# This script handles updating Jellyfin to the latest version

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
JELLYFIN_DIR=${JELLYFIN_DIR:-/home/container}
BACKUP_DIR=${BACKUP_DIR:-/home/container/backups}

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Function to get current Jellyfin version
get_current_version() {
    if [ -x "$JELLYFIN_DIR/jellyfin" ]; then
        "$JELLYFIN_DIR/jellyfin" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown"
    else
        echo "not installed"
    fi
}

# Function to get latest Jellyfin version
get_latest_version() {
    curl -sSL "https://api.github.com/repos/jellyfin/jellyfin/releases/latest" | \
        grep '"tag_name":' | \
        sed -E 's/.*"v?([^"]+)".*/\1/' || echo "unknown"
}

# Function to check if update is available
check_update() {
    local current_version
    local latest_version
    
    current_version=$(get_current_version)
    latest_version=$(get_latest_version)
    
    echo "=== Jellyfin Version Check ==="
    echo "Current version: $current_version"
    echo "Latest version: $latest_version"
    
    if [ "$current_version" = "not installed" ]; then
        warn "Jellyfin is not installed"
        return 2
    elif [ "$current_version" = "unknown" ] || [ "$latest_version" = "unknown" ]; then
        warn "Could not determine version information"
        return 1
    elif [ "$current_version" != "$latest_version" ]; then
        info "Update available: $current_version → $latest_version"
        return 0
    else
        log "Jellyfin is up to date"
        return 1
    fi
}

# Function to perform update
update_jellyfin() {
    local target_version="${1:-latest}"
    local force_update="${2:-false}"
    
    log "Starting Jellyfin update process..."
    
    # Check if update is needed
    if [ "$force_update" != "true" ]; then
        if ! check_update; then
            if [ $? -eq 1 ]; then
                log "No update needed, exiting"
                return 0
            fi
        fi
    fi
    
    # Determine version to download
    if [ "$target_version" = "latest" ]; then
        target_version=$(get_latest_version)
        if [ "$target_version" = "unknown" ]; then
            error "Could not determine latest version"
            return 1
        fi
    fi
    
    log "Updating to version: $target_version"
    
    # Check if Jellyfin is running
    local was_running=false
    if pgrep -f "jellyfin" > /dev/null 2>&1; then
        warn "Jellyfin is running, it will need to be stopped for update"
        was_running=true
    fi
    
    # Create backup before update
    log "Creating backup before update..."
    mkdir -p "$BACKUP_DIR"
    local backup_name="jellyfin-pre-update-$(date +'%Y%m%d-%H%M%S')"
    local backup_path="$BACKUP_DIR/$backup_name.tar.gz"
    
    tar -czf "$backup_path" \
        -C "$(dirname "$JELLYFIN_DIR")" \
        "$(basename "$JELLYFIN_DIR")/jellyfin" \
        "$(basename "$JELLYFIN_DIR")/data" \
        "$(basename "$JELLYFIN_DIR")/config" \
        2>/dev/null || warn "Backup creation failed, continuing anyway..."
    
    # Download new version
    log "Downloading Jellyfin v$target_version..."
    cd /tmp
    
    # Determine architecture
    local arch
    arch=$(uname -m)
    case $arch in
        x86_64)
            arch="amd64"
            ;;
        aarch64)
            arch="arm64"
            ;;
        *)
            error "Unsupported architecture: $arch"
            return 1
            ;;
    esac
    
    # Download
    local download_url="https://github.com/jellyfin/jellyfin/releases/download/v${target_version}/jellyfin_${target_version}_linux-${arch}.tar.gz"
    if ! wget -O "jellyfin-${target_version}.tar.gz" "$download_url"; then
        error "Failed to download Jellyfin v$target_version"
        return 1
    fi
    
    # Stop Jellyfin if running
    if [ "$was_running" = true ]; then
        log "Stopping Jellyfin..."
        pkill -f jellyfin || true
        sleep 5
    fi
    
    # Backup current binary
    if [ -f "$JELLYFIN_DIR/jellyfin" ]; then
        mv "$JELLYFIN_DIR/jellyfin" "$JELLYFIN_DIR/jellyfin.backup"
    fi
    
    # Extract new version
    log "Installing new version..."
    tar -xzf "jellyfin-${target_version}.tar.gz" --strip-components=1 -C "$JELLYFIN_DIR/"
    
    # Set permissions
    chmod +x "$JELLYFIN_DIR/jellyfin"
    chown jellyfin:jellyfin "$JELLYFIN_DIR/jellyfin" 2>/dev/null || true
    
    # Verify installation
    local new_version
    new_version=$(get_current_version)
    if [ "$new_version" = "$target_version" ]; then
        log "Update completed successfully!"
        log "Jellyfin updated to version: $new_version"
        
        # Cleanup
        rm -f "/tmp/jellyfin-${target_version}.tar.gz"
        rm -f "$JELLYFIN_DIR/jellyfin.backup"
        
        if [ "$was_running" = true ]; then
            warn "Please restart Jellyfin through the Pterodactyl panel"
        fi
    else
        error "Update verification failed"
        error "Expected version: $target_version, Got: $new_version"
        
        # Restore backup if available
        if [ -f "$JELLYFIN_DIR/jellyfin.backup" ]; then
            warn "Restoring previous version..."
            mv "$JELLYFIN_DIR/jellyfin.backup" "$JELLYFIN_DIR/jellyfin"
        fi
        
        return 1
    fi
}

# Function to rollback to backup
rollback() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        error "Please specify a backup file for rollback"
        echo "Usage: $0 rollback <backup_file>"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        error "Backup file not found: $backup_file"
        return 1
    fi
    
    log "Rolling back from backup: $backup_file"
    
    # Stop Jellyfin if running
    if pgrep -f "jellyfin" > /dev/null 2>&1; then
        warn "Stopping Jellyfin..."
        pkill -f jellyfin || true
        sleep 5
    fi
    
    # Extract backup
    info "Extracting backup..."
    tar -xzf "$backup_file" -C "$(dirname "$JELLYFIN_DIR")"
    
    if [ $? -eq 0 ]; then
        log "Rollback completed successfully!"
        warn "Please restart Jellyfin through the Pterodactyl panel"
    else
        error "Rollback failed!"
        return 1
    fi
}

# Main script logic
case "$1" in
    check)
        check_update
        ;;
    update)
        update_jellyfin "$2" "$3"
        ;;
    force-update)
        update_jellyfin "$2" "true"
        ;;
    rollback)
        rollback "$2"
        ;;
    *)
        echo "Jellyfin Update Script"
        echo ""
        echo "Usage: $0 {check|update|force-update|rollback}"
        echo ""
        echo "Commands:"
        echo "  check                    - Check if updates are available"
        echo "  update [version]         - Update to latest or specified version"
        echo "  force-update [version]   - Force update even if versions match"
        echo "  rollback <backup_file>   - Rollback to a previous backup"
        echo ""
        exit 1
        ;;
esac