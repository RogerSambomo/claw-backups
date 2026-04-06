#!/bin/bash
#===============================================
# OpenClaw Self-Deploy Script
# Purpose: Deploy Claw to a new server autonomously
# Usage: curl -fsSL https://.../self-deploy.sh | bash
#===============================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

#===============================================
# CONFIGURATION (to be provided by Claw)
#===============================================
GDRIVE_BACKUP_URL=""  # Google Drive backup archive URL
DISCORD_BOT_TOKEN=""   # Discord bot token
MINIMAX_API_KEY=""     # MiniMax API key
OPENCLAW_TOKEN=""      # Gateway token
TARGET_USER=""         # Target user for service

#===============================================
# PHASE 1: Environment Check
#===============================================
phase1_env_check() {
    log_info "Phase 1: Checking environment..."
    
    # Check OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        log_success "Linux detected"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        log_success "macOS detected"
    else
        log_warn "Unsupported OS: $OSTYPE"
    fi
    
    # Check Node.js
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        log_info "Node.js v$(node --version) detected"
        if [[ "$NODE_VERSION" -lt 22 ]]; then
            log_warn "Node.js 22+ recommended. Current: $(node --version)"
        fi
    else
        log_error "Node.js not found. Installing..."
        # Install Node.js 24
        curl -fsSL https://deb.nodesource.com/setup_24.x | bash - || \
        curl -fsSL https://rpm.nodesource.com/setup_24.x | bash -
        apt-get install -y nodejs || yum install -y nodejs
    fi
    
    # Check Git
    if command -v git &> /dev/null; then
        log_success "Git detected"
    else
        log_info "Installing Git..."
        apt-get update && apt-get install -y git
    fi
    
    # Check curl
    if ! command -v curl &> /dev/null; then
        apt-get install -y curl
    fi
    
    log_success "Environment check complete"
}

#===============================================
# PHASE 2: OpenClaw Installation
#===============================================
phase2_install() {
    log_info "Phase 2: Installing OpenClaw..."
    
    # Method 1: Official installer (recommended)
    if command -v openclaw &> /dev/null; then
        log_warn "OpenClaw already installed: $(openclaw --version)"
    else
        log_info "Running official installer..."
        curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-prompt || {
            # Fallback: npm install
            npm install -g openclaw
        }
    fi
    
    # Verify installation
    if command -v openclaw &> /dev/null; then
        log_success "OpenClaw $(openclaw --version) installed"
    else
        log_error "OpenClaw installation failed"
        exit 1
    fi
    
    log_success "OpenClaw installation complete"
}

#===============================================
# PHASE 3: Directory Setup
#===============================================
phase3_directories() {
    log_info "Phase 3: Setting up directories..."
    
    # Create OpenClaw directories
    mkdir -p ~/.openclaw
    mkdir -p ~/.openclaw/agents
    mkdir -p ~/.openclaw/agents/main/agent
    mkdir -p ~/.openclaw/agents/main/sessions
    mkdir -p ~/.openclaw/workspace
    mkdir -p ~/.openclaw-dev
    mkdir -p ~/.neuralmemory
    mkdir -p ~/.config/openclaw
    
    log_success "Directories created"
}

#===============================================
# PHASE 4: Configuration
#===============================================
phase4_configure() {
    log_info "Phase 4: Configuring OpenClaw..."
    
    # Create基础配置
    cat > ~/.openclaw/openclaw.json << 'CONFIG_EOF'
{
  "meta": {
    "lastTouchedVersion": "2026.4.2",
    "lastTouchedAt": "'$(date -Iseconds)'"
  },
  "agents": {
    "defaults": {
      "workspace": "/home/$TARGET_USER/.openclaw/workspace"
    }
  },
  "commands": {
    "native": "auto",
    "nativeSkills": "auto"
  },
  "gateway": {
    "port": 18789,
    "bind": "loopback",
    "auth": {
      "mode": "token",
      "token": "'$OPENCLAW_TOKEN'"
    }
  },
  "channels": {}
}
CONFIG_EOF

    # Create dev config
    cat > ~/.openclaw-dev/openclaw.json << 'DEVCONFIG_EOF'
{
  "meta": {
    "lastTouchedVersion": "2026.4.2"
  },
  "agents": {
    "defaults": {
      "workspace": "/home/'$TARGET_USER'/.openclaw/workspace-dev"
    }
  },
  "gateway": {
    "port": 19001,
    "bind": "loopback"
  }
}
DEVCONFIG_EOF

    # Set API keys as environment variables for now
    export MINIMAX_API_KEY="$MINIMAX_API_KEY"
    export DISCORD_BOT_TOKEN="$DISCORD_BOT_TOKEN"
    
    log_success "Configuration files created"
}

#===============================================
# PHASE 5: Service Setup
#===============================================
phase5_service() {
    log_info "Phase 5: Setting up systemd service..."
    
    # Enable linger for user service
    log_info "Enabling linger for user services..."
    sudo loginctl enable-linger $USER 2>/dev/null || true
    
    # Install OpenClaw as user service
    openclaw onboard --install-daemon 2>/dev/null || {
        log_warn "Daemon installation failed, trying manual setup..."
        
        # Create systemd user service manually
        mkdir -p ~/.config/systemd/user
        cat > ~/.config/systemd/user/openclaw-gateway.service << 'SERVICE_EOF'
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/openclaw gateway run
Restart=always
RestartSec=10
Environment=OPENCLAW_GATEWAY_PORT=18789

[Install]
WantedBy=default.target
SERVICE_EOF
        
        systemctl --user daemon-reload
        systemctl --user enable openclaw-gateway
        systemctl --user start openclaw-gateway
    }
    
    log_success "Service setup complete"
}

#===============================================
# PHASE 6: Health Check
#===============================================
phase6_health_check() {
    log_info "Phase 6: Running health checks..."
    
    # Wait for gateway to start
    sleep 5
    
    # Check gateway status
    if openclaw gateway status 2>/dev/null | grep -q "running"; then
        log_success "Gateway is running"
    else
        log_warn "Gateway may not be running yet"
    fi
    
    # Run doctor
    log_info "Running OpenClaw doctor..."
    openclaw doctor --non-interactive || true
    
    log_success "Health check complete"
}

#===============================================
# MAIN EXECUTION
#===============================================
main() {
    echo "==============================================="
    echo "  OpenClaw Self-Deploy Script"
    echo "  Deploying Claw to new server autonomously"
    echo "==============================================="
    echo ""
    
    # Check if running as root (not recommended)
    if [[ $EUID -eq 0 ]]; then
        log_error "Running as root is not recommended!"
        log_info "Please run as a normal user with sudo privileges"
        exit 1
    fi
    
    # Execute phases
    phase1_env_check
    phase2_install
    phase3_directories
    phase4_configure
    phase5_service
    phase6_health_check
    
    echo ""
    echo "==============================================="
    log_success "OpenClaw deployment complete!"
    echo "==============================================="
    echo ""
    echo "Next steps:"
    echo "  1. Configure your AI provider API keys"
    echo "  2. Set up channels (Discord, Telegram, etc.)"
    echo "  3. Restore your memory and workspace from backup"
    echo ""
    echo "Useful commands:"
    echo "  openclaw gateway status   - Check gateway status"
    echo "  openclaw doctor           - Run diagnostics"
    echo "  openclaw logs             - View logs"
    echo ""
}

# Run main function
main "$@"
