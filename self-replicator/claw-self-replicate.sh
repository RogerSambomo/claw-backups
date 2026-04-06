#!/bin/bash
#===============================================
# Claw Self-Replication Script
# Purpose: Fully autonomous deployment from backup
#===============================================

set -e

GDRIVE_FOLDER_ID=""  # Google Drive folder ID with backups
TARGET_USER="${USER:-ubuntu}"
BACKUP_DATE="latest"

log() { echo "[$(date '+%H:%M:%S')] $*"; }
log "=========================================="
log "  Claw Self-Replication Starting"
log "=========================================="

#---------------------------------------
# STEP 1: Check prerequisites
#---------------------------------------'
log "[1/8] Checking prerequisites..."'
if ! command -v curl &>/dev/null; then
    apt-get update && apt-get install -y curl unzip
fi

if ! command -v jq &>/dev/null; then
    apt-get install -y jq
fi

if ! command -v gdrive &>/dev/null; then
    # Install gdrive (Google Drive CLI)
    curl -fsSL https://github.com/prasmussen/gdrive/releases/download/2.1.1/gdrive_2.1.1_linux_amd64.tar.gz -o /tmp/gdrive.tar.gz
    tar -xzf /tmp/gdrive.tar.gz -C /tmp
    chmod +x /tmp/gdrive
    mv /tmp/gdrive /usr/local/bin/
fi

#---------------------------------------
# STEP 2: Download backups from Google Drive
#---------------------------------------
log "[2/8] Downloading backups from Google Drive..."

# List backups in folder
log "Available backups:"
gdrive list --no-header --name-width 0 2>/dev/null | grep "openclaw" | head -5 || {
    log "ERROR: Cannot access Google Drive"
    log "Please ensure gdrive is authenticated: gdrive list"
    exit 1
}

# Download latest backup
BACKUP_FILE="openclaw-backup-$(date +%Y%m%d).tar.gz"
log "Downloading backup to /tmp/$BACKUP_FILE..."
gdrive download --force --path /tmp "$(gdrive list --no-header | grep openclaw | head -1 | awk '{print $1}')" 2>/dev/null || {
    log "ERROR: Failed to download backup"
    exit 1
}

#---------------------------------------
# STEP 3: Stop existing OpenClaw
#---------------------------------------'
log "[3/8] Stopping existing OpenClaw services..."'
systemctl --user stop openclaw-gateway 2>/dev/null || true
pkill -f "openclaw.*gateway" 2>/dev/null || true
sleep 2

#---------------------------------------
# STEP 4: Backup current state
#---------------------------------------
log "[4/8] Backing up current state..."
mkdir -p ~/.openclaw-backup-old
cp -r ~/.openclaw/* ~/.openclaw-backup-old/ 2>/dev/null || true
cp -r ~/.openclaw-dev/* ~/.openclaw-backup-old/ 2>/dev/null || true

#---------------------------------------
# STEP 5: Extract backup
#---------------------------------------
log "[5/8] Extracting backup..."
cd ~
tar -xzf /tmp/openclaw-*.tar.gz 2>/dev/null || {
    # Try alternate extraction
    tar -xzf /tmp/backup.tar.gz 2>/dev/null || {
        log "ERROR: Failed to extract backup"
        exit 1
    }
}

#---------------------------------------
# STEP 6: Restore OpenClaw configs
#---------------------------------------
log "[6/8] Restoring OpenClaw configuration..."

# Restore main config
if [ -f backup/openclaw/openclaw.json ]; then
    cp backup/openclaw/openclaw.json ~/.openclaw/
    cp -r backup/openclaw/agents/* ~/.openclaw/agents/ 2>/dev/null || true
    cp -r backup/openclaw/workspace/* ~/.openclaw/workspace/ 2>/dev/null || true
fi

# Restore dev config
if [ -d backup/openclaw-dev ]; then
    cp backup/openclaw-dev/openclaw.json ~/.openclaw-dev/ 2>/dev/null || true
    cp -r backup/openclaw-dev/agents ~/.openclaw-dev/ 2>/dev/null || true
fi

# Restore neural memory
if [ -d backup/.neuralmemory ]; then
    cp -r backup/.neuralmemory/* ~/.neuralmemory/ 2>/dev/null || true
fi

#---------------------------------------
# STEP 7: Restart OpenClaw
#---------------------------------------'
log "[7/8] Restarting OpenClaw..."

# Start gateway
openclaw gateway run &
sleep 5

#---------------------------------------
# STEP 8: Verify deployment
#---------------------------------------'
log "[8/8] Verifying deployment..."

if curl -s http://127.0.0.1:18789/ > /dev/null 2>&1; then
    log "SUCCESS: OpenClaw is running on port 18789"
else
    log "WARNING: Gateway may not be fully started yet"
    log "Check status with: openclaw gateway status"
fi

# Run health check
openclaw doctor --non-interactive 2>/dev/null || true

log "=========================================="
log "  Self-Replication Complete!"
log "=========================================="
log ""
log "Your Claw instance has been restored!"
log "Gateway: http://127.0.0.1:18789"
