#!/bin/bash

# Jellyfin Server Management Script
# This script provides common management functions for Jellyfin

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
JELLYFIN_DATA_DIR=${JELLYFIN_DATA_DIR:-/home/container/data}
JELLYFIN_CONFIG_DIR=${JELLYFIN_CONFIG_DIR:-/home/container/config}
JELLYFIN_LOG_DIR=${JELLYFIN_LOG_DIR:-/home/container/logs}
JELLYFIN_CACHE_DIR=${JELLYFIN_CACHE_DIR:-/home/container/cache}
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

# Function to check if Jellyfin is running
is_running() {
    pgrep -f "jellyfin" > /dev/null 2>&1
}

# Function to get server status
status() {
    echo "=== Jellyfin Server Status ==="
    if is_running; then
        log "Jellyfin is RUNNING"
        echo "Process ID: $(pgrep -f jellyfin)"
        
        # Check if web interface is accessible
        if curl -s -o /dev/null -w "%{http_code}" "http://localhost:${SERVER_PORT:-8096}/health" | grep -q "200"; then
            log "Web interface is accessible"
        else
            warn "Web interface may not be accessible"
        fi
    else
        warn "Jellyfin is NOT RUNNING"
    fi
    
    echo ""
    echo "=== Directory Information ==="
    echo "Data Directory: $JELLYFIN_DATA_DIR"
    echo "Config Directory: $JELLYFIN_CONFIG_DIR"
    echo "Log Directory: $JELLYFIN_LOG_DIR"
    echo "Cache Directory: $JELLYFIN_CACHE_DIR"
    
    echo ""
    echo "=== Disk Usage ==="
    du -sh "$JELLYFIN_DATA_DIR" 2>/dev/null | awk '{print "Data: " $1}' || echo "Data: N/A"
    du -sh "$JELLYFIN_CONFIG_DIR" 2>/dev/null | awk '{print "Config: " $1}' || echo "Config: N/A"
    du -sh "$JELLYFIN_CACHE_DIR" 2>/dev/null | awk '{print "Cache: " $1}' || echo "Cache: N/A"
    du -sh "$JELLYFIN_LOG_DIR" 2>/dev/null | awk '{print "Logs: " $1}' || echo "Logs: N/A"
}

# Function to backup Jellyfin data
backup() {
    local backup_name="jellyfin-backup-$(date +'%Y%m%d-%H%M%S')"
    local backup_path="$BACKUP_DIR/$backup_name.tar.gz"
    
    log "Creating backup: $backup_name"
    
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    # Stop Jellyfin if running
    local was_running=false
    if is_running; then
        warn "Jellyfin is running, stopping for backup..."
        pkill -f jellyfin || true
        sleep 5
        was_running=true
    fi
    
    # Create backup
    info "Backing up data and configuration..."
    tar -czf "$backup_path" \
        -C "$(dirname "$JELLYFIN_DATA_DIR")" "$(basename "$JELLYFIN_DATA_DIR")" \
        -C "$(dirname "$JELLYFIN_CONFIG_DIR")" "$(basename "$JELLYFIN_CONFIG_DIR")" \
        2>/dev/null
    
    if [ $? -eq 0 ]; then
        log "Backup created successfully: $backup_path"
        echo "Backup size: $(du -sh "$backup_path" | awk '{print $1}')"
    else
        error "Backup failed!"
        return 1
    fi
    
    # Restart Jellyfin if it was running
    if [ "$was_running" = true ]; then
        info "Restarting Jellyfin..."
        # This would typically be handled by Pterodactyl
        warn "Please restart the server through Pterodactyl panel"
    fi
}

# Function to restore from backup
restore() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        error "Please specify a backup file to restore from"
        echo "Usage: $0 restore <backup_file>"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        error "Backup file not found: $backup_file"
        return 1
    fi
    
    log "Restoring from backup: $backup_file"
    
    # Stop Jellyfin if running
    if is_running; then
        warn "Jellyfin is running, stopping for restore..."
        pkill -f jellyfin || true
        sleep 5
    fi
    
    # Backup current data (just in case)
    local current_backup="$BACKUP_DIR/pre-restore-$(date +'%Y%m%d-%H%M%S').tar.gz"
    warn "Creating safety backup before restore: $current_backup"
    mkdir -p "$BACKUP_DIR"
    tar -czf "$current_backup" \
        -C "$(dirname "$JELLYFIN_DATA_DIR")" "$(basename "$JELLYFIN_DATA_DIR")" \
        -C "$(dirname "$JELLYFIN_CONFIG_DIR")" "$(basename "$JELLYFIN_CONFIG_DIR")" \
        2>/dev/null || warn "Could not create safety backup"
    
    # Remove current data and config
    info "Removing current data and configuration..."
    rm -rf "$JELLYFIN_DATA_DIR" "$JELLYFIN_CONFIG_DIR"
    
    # Extract backup
    info "Extracting backup..."
    tar -xzf "$backup_file" -C "$(dirname "$JELLYFIN_DATA_DIR")" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log "Restore completed successfully!"
        warn "Please restart the server through Pterodactyl panel"
    else
        error "Restore failed!"
        return 1
    fi
}

# Function to clean cache
clean_cache() {
    log "Cleaning Jellyfin cache..."
    
    if is_running; then
        warn "Jellyfin is running, stopping for cache cleanup..."
        pkill -f jellyfin || true
        sleep 5
    fi
    
    local cache_size_before
    cache_size_before=$(du -sh "$JELLYFIN_CACHE_DIR" 2>/dev/null | awk '{print $1}' || echo "0")
    
    rm -rf "$JELLYFIN_CACHE_DIR"/*
    
    log "Cache cleaned successfully!"
    echo "Space freed: $cache_size_before"
    warn "Please restart the server through Pterodactyl panel"
}

# Function to show logs
logs() {
    local lines=${1:-50}
    echo "=== Last $lines lines of Jellyfin logs ==="
    
    if [ -f "$JELLYFIN_LOG_DIR/jellyfin.log" ]; then
        tail -n "$lines" "$JELLYFIN_LOG_DIR/jellyfin.log"
    else
        warn "No log file found at $JELLYFIN_LOG_DIR/jellyfin.log"
    fi
}

# Function to list backups
list_backups() {
    echo "=== Available Backups ==="
    if [ -d "$BACKUP_DIR" ] && [ "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        ls -la "$BACKUP_DIR"/*.tar.gz 2>/dev/null | awk '{print $9 " (" $5 " bytes, " $6 " " $7 " " $8 ")"}'
    else
        info "No backups found in $BACKUP_DIR"
    fi
}

# Main script logic
case "$1" in
    status)
        status
        ;;
    backup)
        backup
        ;;
    restore)
        restore "$2"
        ;;
    clean-cache)
        clean_cache
        ;;
    logs)
        logs "$2"
        ;;
    list-backups)
        list_backups
        ;;
    *)
        echo "Jellyfin Management Script"
        echo ""
        echo "Usage: $0 {status|backup|restore|clean-cache|logs|list-backups}"
        echo ""
        echo "Commands:"
        echo "  status       - Show server status and disk usage"
        echo "  backup       - Create a backup of data and configuration"
        echo "  restore      - Restore from a backup file"
        echo "  clean-cache  - Clean the Jellyfin cache directory"
        echo "  logs [lines] - Show recent log entries (default: 50 lines)"
        echo "  list-backups - List available backup files"
        echo ""
        exit 1
        ;;
esac