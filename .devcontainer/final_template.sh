#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation mode flags
INSTALL_MODE=""  # Can be "prod", "debug", or empty (interactive)
SKIP_OPENAI_SETUP=false

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --prod-install)
                INSTALL_MODE="prod"
                shift
                ;;
            --debug-install)
                INSTALL_MODE="debug"
                shift
                ;;
            --no-openai-embedder-registration)
                SKIP_OPENAI_SETUP=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Show help message
show_help() {
    echo "GoodMem Installation Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --prod-install                     Install in production mode (database port not exposed)"
    echo "  --debug-install                    Install in debug mode (database port exposed on 5432)"
    echo "  --no-openai-embedder-registration  Skip OpenAI embedder setup (unattended mode)"
    echo "  --help, -h                         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                 Interactive installation with mode selection"
    echo "  $0 --prod-install                 Unattended production installation"
    echo "  $0 --debug-install --no-openai-embedder-registration"
    echo "                                     Unattended debug installation without OpenAI setup"
    echo ""
}

# Helper functions
log_info() {
    printf "${BLUE}[INFO]${NC} %s\n" "$1"
}

log_success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"
}

log_warning() {
    printf "${YELLOW}[WARNING]${NC} %s\n" "$1"
}

log_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

show_logo() {
    echo "      ___           ___           ___           ___           ___           ___           ___     "
    echo "     /\  \         /\  \         /\  \         /\  \         /\__\         /\  \         /\__\    "
    echo "    /::\  \       /::\  \       /::\  \       /::\  \       /::|  |       /::\  \       /::|  |   "
    echo "   /:/\:\  \     /:/\:\  \     /:/\:\  \     /:/\:\  \     /:|:|  |      /:/\:\  \     /:|:|  |   "
    echo "  /:/  \:\  \   /:/  \:\  \   /:/  \:\  \   /:/  \:\__\   /:/|:|__|__   /::\~\:\  \   /:/|:|__|__ "
    echo " /:/__/_\:\__\ /:/__/ \:\__\ /:/__/ \:\__\ /:/__/ \:|__| /:/ |::::\__\ /:/\:\ \:\__\ /:/ |::::\__\\"
    echo " \:\  /\ \/__/ \:\  \ /:/  / \:\  \ /:/  / \:\  \ /:/  / \/__/~~/:/  / \:\~\:\ \/__/ \/__/~~/:/  /"
    echo "  \:\ \:\__\    \:\  /:/  /   \:\  /:/  /   \:\  /:/  /        /:/  /   \:\ \:\__\         /:/  / "
    echo "   \:\/:/  /     \:\/:/  /     \:\/:/  /     \:\/:/  /        /:/  /     \:\ \/__/        /:/  /  "
    echo "    \::/  /       \::/  /       \::/  /       \::/__/        /:/  /       \:\__\         /:/  /   "
    echo "     \/__/         \/__/         \/__/         ~~            \/__/         \/__/         \/__/    "
    echo ""
    echo "                                   Memory APIs with CLI and UI"
    echo ""
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Prompt for installation mode if not specified
prompt_installation_mode() {
    if [[ -n "$INSTALL_MODE" ]]; then
        log_info "Installation mode: $INSTALL_MODE (specified via command line)"
        return 0
    fi
    
    echo ""
    echo "🔧 Installation Mode Selection"
    echo ""
    echo "Choose your installation mode:"
    echo "  1) Production mode (database port not exposed, recommended for servers)"
    echo "  2) Debug mode (database port exposed on 5432, useful for development)"
    echo ""
    
    while true; do
        read -p "Select mode (1 for production, 2 for debug): " -n 1 -r </dev/tty
        echo
        case $REPLY in
            1)
                INSTALL_MODE="prod"
                log_info "Selected: Production mode"
                break
                ;;
            2)
                INSTALL_MODE="debug"
                log_info "Selected: Debug mode (database accessible on localhost:5432)"
                break
                ;;
            *)
                echo "Please enter 1 or 2"
                ;;
        esac
    done
    echo ""
}

# Detect OS and architecture
detect_platform() {
    local os
    local arch
    
    # Detect OS
    case "$(uname -s)" in
        Linux*)     os="linux" ;;
        Darwin*)    os="darwin" ;;
        CYGWIN*|MINGW*|MSYS*) os="windows" ;;
        *)          os="unknown" ;;
    esac
    
    # Detect architecture
    case "$(uname -m)" in
        x86_64|amd64)   arch="amd64" ;;
        arm64|aarch64)  arch="arm64" ;;
        armv7l)         arch="arm" ;;
        *)              arch="unknown" ;;
    esac
    
    echo "${os}-${arch}"
}

# Check Docker installation
check_docker() {
    log_info "Checking Docker installation..."
    
    if command_exists docker; then
        if docker info >/dev/null 2>&1; then
            log_success "Docker is installed and running"
            return 0
        else
            log_warning "Docker is installed but not running"
            return 1
        fi
    else
        log_warning "Docker is not installed"
        return 1
    fi
}

# Install Docker
install_docker() {
    local platform
    platform=$(detect_platform)
    
    log_info "Installing Docker for platform: $platform"
    
    case "$platform" in
        linux-*)
            log_info "Installing Docker using the official installation script..."
            curl -fsSL https://get.docker.com | sh
            
            # Add current user to docker group
            if ! groups | grep -q docker; then
                log_info "Adding current user to docker group..."
                sudo usermod -aG docker "$USER"
                log_warning "You may need to log out and back in for Docker group changes to take effect"
            fi
            ;;
        macos-*)
            log_error "Please install Docker Desktop for Mac from: https://docker.com/products/docker-desktop"
            log_error "Then run this installer again"
            exit 1
            ;;
        windows-*)
            log_error "Please install Docker Desktop for Windows from: https://docker.com/products/docker-desktop"
            log_error "Then run this installer again"
            exit 1
            ;;
        *)
            log_error "Unsupported platform: $platform"
            log_error "Please install Docker manually and run this installer again"
            exit 1
            ;;
    esac
}

# Download GoodMem configuration files
download_goodmem_files() {
    local goodmem_dir="${GOODMEM_DIR:-$HOME/.goodmem}"
    local base_url="https://get.goodmem.ai"
    
    log_info "Setting up GoodMem directory: $goodmem_dir"
    
    # Create directory structure
    mkdir -p "$goodmem_dir"
    mkdir -p "$goodmem_dir/data/pgdata"
    mkdir -p "$goodmem_dir/data/database"
    
    # Download and customize docker-compose.yml based on installation mode
    log_info "Downloading and configuring docker-compose.yml for $INSTALL_MODE mode..."
    local temp_compose
    temp_compose=$(mktemp)
    
    if command_exists curl; then
        curl -fsSL "$base_url/docker-compose.yml" > "$temp_compose"
    elif command_exists wget; then
        wget -qO "$temp_compose" "$base_url/docker-compose.yml"
    else
        log_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    
    # Modify docker-compose.yml based on installation mode
    if [[ "$INSTALL_MODE" == "prod" ]]; then
        log_info "Configuring for production mode (database port not exposed)..."
        # Remove the database port mapping for production using awk
        awk '
        BEGIN { in_db_section = 0; skip_ports = 0 }
        /^  db:$/ { in_db_section = 1; print; next }
        /^  [a-zA-Z]/ && !/^  db:$/ { in_db_section = 0; skip_ports = 0; print; next }
        in_db_section && /^    ports:$/ { 
            print "    # Database port not exposed in production mode"
            skip_ports = 1
            next 
        }
        in_db_section && skip_ports && /^      - "5432:5432"$/ { 
            skip_ports = 0
            next 
        }
        { print }
        ' "$temp_compose" > "$goodmem_dir/docker-compose.yml"
    elif [[ "$INSTALL_MODE" == "debug" ]]; then
        log_info "Configuring for debug mode (database port exposed on 5432, JobRunr dashboard on 8001)..."
        # Add debug port 8001 for JobRunr dashboard
        awk '
        BEGIN { in_server_section = 0; ports_found = 0 }
        /^  server:$/ { in_server_section = 1; print; next }
        /^  [a-zA-Z]/ && !/^  server:$/ { in_server_section = 0; ports_found = 0; print; next }
        in_server_section && /^    ports:$/ { 
            ports_found = 1; print; next 
        }
        in_server_section && ports_found && /^      - "9090:9090"/ { 
            print
            print "      - \"8001:8001\"  # JobRunr Dashboard (debug mode)"
            next 
        }
        { print }
        ' "$temp_compose" > "$goodmem_dir/docker-compose.yml"
    else
        log_error "Invalid installation mode: $INSTALL_MODE"
        rm -f "$temp_compose"
        exit 1
    fi
    
    # Clean up temp file
    rm -f "$temp_compose"
    
    # Download database initialization scripts
    log_info "Downloading database initialization scripts..."
    for script in "00-extensions.sql" "01-schema.sql" "02-jobrunr-schema.sql"; do
        log_info "  Downloading $script..."
        if command_exists curl; then
            curl -fsSL "$base_url/database/$script" > "$goodmem_dir/data/database/$script"
        else
            wget -qO "$goodmem_dir/data/database/$script" "$base_url/database/$script"
        fi
    done
    
    log_success "GoodMem files downloaded and configured successfully"
}

# Install CLI binary
install_cli() {
    local platform
    platform=$(detect_platform)
    local base_url="https://get.goodmem.ai"
    local cli_dir="${CLI_INSTALL_DIR:-/usr/local/bin}"
    local binary_name="goodmem"
    
    # Add .exe extension for Windows
    case "$platform" in
        windows-*)
            binary_name="goodmem.exe"
            ;;
    esac
    
    log_info "Installing GoodMem CLI for platform: $platform"
    
    # Check if we need sudo for installation
    local use_sudo=""
    if [ ! -w "$cli_dir" ]; then
        log_info "Installation directory requires elevated privileges"
        use_sudo="sudo"
    fi
    
    # Determine archive format based on platform
    local archive_file
    case "$platform" in
        windows-*)
            archive_file="goodmem-$platform.zip"
            ;;
        *)
            archive_file="goodmem-$platform.tar.gz"
            ;;
    esac
    
    # Check that required extraction tool is available
    local need
    case "$platform" in
        windows-*) need=unzip ;;
        *)         need=tar ;;
    esac
    if ! command_exists "$need"; then
        log_error "Required tool '$need' not found. Install it and retry."
        return 1
    fi
    
    # Download CLI archive
    log_info "Downloading CLI archive ($archive_file)..."
    local temp_archive
    temp_archive=$(mktemp)
    
    if command_exists curl; then
        if ! curl -fsSL "$base_url/cli/$archive_file" > "$temp_archive"; then
            log_error "Failed to download CLI archive for platform: $platform"
            rm -f "$temp_archive"
            return 1
        fi
    elif command_exists wget; then
        if ! wget -qO "$temp_archive" "$base_url/cli/$archive_file"; then
            log_error "Failed to download CLI archive for platform: $platform"
            rm -f "$temp_archive"
            return 1
        fi
    else
        log_error "Neither curl nor wget found. Please install one of them."
        return 1
    fi
    
    # Extract and install binary
    log_info "Extracting and installing CLI binary..."
    local temp_dir
    temp_dir=$(mktemp -d)
    
    # Extract the archive
    case "$platform" in
        windows-*)
            if ! unzip -j "$temp_archive" -d "$temp_dir" >/dev/null 2>&1; then
                log_error "Failed to extract CLI archive"
                rm -f "$temp_archive"
                rm -rf "$temp_dir"
                return 1
            fi
            ;;
        *)
            if ! tar -xzf "$temp_archive" -C "$temp_dir" >/dev/null 2>&1; then
                log_error "Failed to extract CLI archive"
                rm -f "$temp_archive"
                rm -rf "$temp_dir"
                return 1
            fi
            ;;
    esac
    
    # --- START OF THE FIX ---
    # Robustly find the binary by its name pattern, not by fragile permissions.
    log_info "Searching for binary in extracted files..."
    local extracted_binary
    extracted_binary=$(find "$temp_dir" -type f -name 'goodmem*' ! -name '*.zip' ! -name '*.tar.gz' | head -n1)
    # --- END OF THE FIX ---

    if [ -z "$extracted_binary" ]; then
        log_error "Could not find goodmem binary in archive"
        rm -f "$temp_archive"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Install binary
    log_info "Installing CLI binary to $cli_dir/$binary_name..."
    if ! $use_sudo install -m 755 "$extracted_binary" "$cli_dir/$binary_name"; then
        log_error "Failed to install CLI binary"
        rm -f "$temp_archive"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Clean up
    rm -f "$temp_archive"
    rm -rf "$temp_dir"
    
    # Verify installation
    if command_exists "$binary_name"; then
        log_success "CLI installed successfully"
        log_info "CLI version: $($binary_name version 2>/dev/null || echo 'unknown')"
    else
        log_warning "CLI installed but not found in PATH. You may need to restart your shell or add $cli_dir to your PATH"
    fi
    
    return 0
}

# Start GoodMem services
start_goodmem() {
    local goodmem_dir="${GOODMEM_DIR:-$HOME/.goodmem}"
    
    log_info "Starting GoodMem services..."
    
    # Set environment variables
    export DATA_DIR_BASE="$goodmem_dir/data"
    export POSTGRES_USER="${POSTGRES_USER:-goodmem_user}"
    export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-goodmem_password}"
    export POSTGRES_DB="${POSTGRES_DB:-goodmem_db}"
    
    # Change to goodmem directory and start services
    cd "$goodmem_dir"
    
    log_info "Pulling Docker images..."
    docker compose pull
    
    log_info "Starting services (this may take a few minutes)..."
    docker compose up -d
    
    log_success "GoodMem services started"
}

# Setup default OpenAI embedder
setup_default_embedder() {
    # Check if OpenAI setup should be skipped
    if [[ "$SKIP_OPENAI_SETUP" == true ]]; then
        log_info "Skipping OpenAI embedder setup (--no-openai-embedder-registration specified)"
        return 0
    fi
    
    log_info "Setting up default embedder..."
    
    # Check if CLI is available
    if ! command_exists goodmem; then
        log_warning "GoodMem CLI not found in PATH. Skipping embedder setup."
        return 1
    fi
    
    # Check if embedders already exist
    local embedder_list
    if embedder_list=$(goodmem embedder list 2>/dev/null); then
        if ! echo "$embedder_list" | grep -q "No embedders found"; then
            log_info "Embedders already exist. Skipping default embedder setup."
            echo "$embedder_list"
            return 0
        fi
    fi
    
    echo ""
    echo "🤖 Default Embedder Setup"
    echo ""
    echo "We can help you set up OpenAI's text-embedding-3-small model (1536 dimensions)."
    echo "This model is compatible with GoodMem's vector storage limits."
    echo ""
    echo "Note: text-embedding-3-large (3072 dimensions) exceeds GoodMem's 1536-dimension limit."
    echo "For other providers or models, use: goodmem embedder create"
    echo ""
    
    # Ask if user wants to set up OpenAI embedder
    read -p "Would you like to set up OpenAI text-embedding-3-small? (y/n): " -n 1 -r </dev/tty
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping OpenAI embedder setup."
        echo "You can create embedders manually with: goodmem embedder create"
        return 0
    fi
    
    # Get OpenAI API key
    echo ""
    echo "Please enter your OpenAI API key (starts with 'sk-'):"
    read -s -p "OpenAI API Key: " openai_api_key </dev/tty
    echo
    
    if [[ -z "$openai_api_key" ]]; then
        log_warning "No API key provided. Skipping embedder setup."
        return 1
    fi
    
    if [[ ! "$openai_api_key" =~ ^sk- ]]; then
        log_warning "API key doesn't look like an OpenAI key (should start with 'sk-')"
        log_warning "Continuing anyway..."
    fi
    
    # Create the OpenAI embedder
    log_info "Creating OpenAI text-embedding-3-small embedder..."
    local embedder_output
    if embedder_output=$(goodmem embedder create \
        --endpoint-url "https://api.openai.com/v1" \
        --display-name "OpenAI text-embedding-3-small" \
        --dimensionality 1536 \
        --modality TEXT \
        --model-identifier "text-embedding-3-small" \
        --provider-type OPENAI \
        --distribution-type DENSE \
        --version "1.0.0" \
        --credentials="$openai_api_key" 2>&1); then
        
        log_success "OpenAI embedder created successfully!"
        echo "$embedder_output"
        
        # Extract embedder UUID for potential space creation
        local embedder_uuid
        embedder_uuid=$(echo "$embedder_output" | grep "ID:" | awk '{print $2}')
        
        if [[ -n "$embedder_uuid" ]]; then
            # Ask if user wants to create a default space
            echo ""
            read -p "Would you like to create a default space called 'My Memories'? (y/n): " -n 1 -r </dev/tty
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log_info "Creating default space..."
                if goodmem space create --name "My Memories" --embedder-id "$embedder_uuid" 2>/dev/null; then
                    log_success "Default space 'My Memories' created successfully!"
                else
                    log_warning "Failed to create default space. You can create one manually with: goodmem space create"
                fi
            fi
        fi
        
        return 0
    else
        log_error "Failed to create OpenAI embedder:"
        echo "$embedder_output"
        log_warning "You can create embedders manually with: goodmem embedder create"
        return 1
    fi
}

# Initialize GoodMem system
initialize_goodmem_system() {
    log_info "Initializing GoodMem system..."
    
    # Check if CLI is available
    if ! command_exists goodmem; then
        log_warning "GoodMem CLI not found in PATH. Skipping system initialization."
        log_warning "You can initialize the system manually by running: goodmem init"
        return 1
    fi
    
    # Give the gRPC server additional time to be ready
    log_info "Waiting for gRPC server to be fully ready..."
    sleep 10
    
    # Run goodmem init and capture output
    local init_output
    if init_output=$(goodmem init 2>&1); then
        log_success "System initialized successfully!"
        
        # Extract and display the important information
        echo ""
        echo "🔑 System Initialization Complete!"
        echo ""
        echo "$init_output"
        echo ""
        log_warning "IMPORTANT: Save the root API key securely. It will not be shown again."
        echo ""
        
        return 0
    else
        log_error "Failed to initialize GoodMem system:"
        echo "$init_output"
        log_warning "You can initialize the system manually by running: goodmem init"
        return 1
    fi
}

# Verify the installation
verify_installation() {
    local goodmem_dir="${GOODMEM_DIR:-$HOME/.goodmem}"
    
    log_info "Verifying installation..."
    
    # Wait for services to be ready
    log_info "Waiting for services to be healthy..."
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if docker compose ps --format json | grep -q '"Health":"healthy"'; then
            log_success "Database is healthy"
            break
        fi
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    
    if [ $attempt -eq $max_attempts ]; then
        log_warning "Services may still be starting. Check with: docker compose logs"
    fi
    
    # Test server endpoint
    log_info "Testing server connectivity..."
    sleep 5  # Give server a moment to start
    
    if command_exists curl; then
        if curl -s -f http://localhost:8080 >/dev/null 2>&1; then
            log_success "Server is responding on port 8080"
        else
            log_warning "Server may still be starting. Check with: docker compose logs server"
        fi
    fi
    
    log_success "GoodMem installation complete!"
    echo ""
    echo "🎉 GoodMem is now running!"
    echo ""
    echo "Access points:"
    echo "  • REST API: http://localhost:8080"
    echo "  • gRPC API: localhost:9090"
    if [[ "$INSTALL_MODE" == "debug" ]]; then
        echo "  • Database: localhost:5432 (debug mode)"
    else
        echo "  • Database: Internal only (production mode)"
    fi
    echo "  • JobRunr Dashboard: http://localhost:8001"
    echo ""
    echo "Management commands:"
    echo "  • View logs:    cd $goodmem_dir && docker compose logs -f"
    echo "  • Stop:         cd $goodmem_dir && docker compose down"
    echo "  • Restart:      cd $goodmem_dir && docker compose restart"
    echo ""
}

# Main installation function
main() {
    # Parse command line arguments first
    parse_arguments "$@"
    
    show_logo
    
    log_info "Starting GoodMem installation..."
    log_info "Platform: $(detect_platform)"
    
    # Prompt for installation mode if not specified via command line
    prompt_installation_mode
    
    # Check and install Docker if needed
    if ! check_docker; then
        log_info "Docker installation required..."
        install_docker
        
        # Verify Docker installation
        if ! check_docker; then
            log_error "Docker installation failed or Docker daemon is not running"
            log_error "Please install Docker manually and ensure it's running"
            exit 1
        fi
    fi
    
    log_success "Docker is ready!"
    
    # Download GoodMem files
    download_goodmem_files
    
    # Install CLI
    if ! install_cli; then
        log_warning "CLI installation failed, but continuing with server installation"
        log_warning "You can install the CLI manually from: https://github.com/PAIR-Systems-Inc/goodmem/releases"
    fi
    
    # Start GoodMem services
    start_goodmem
    
    # Verify installation
    verify_installation
    
    # Initialize GoodMem system
    initialize_goodmem_system
    
    # Setup default embedder (only if initialization succeeded)
    if [ $? -eq 0 ]; then
        setup_default_embedder
    fi
}

# Run main function
main "$@"
