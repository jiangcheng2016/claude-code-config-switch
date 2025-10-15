#!/bin/bash

# Claude Configuration Switcher
# A tool for managing multiple Claude API configurations
#
# Copyright 2024 Claude Configuration Switcher Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Version: 1.0.0
# Date: 2024-01-15

set -euo pipefail

# Configuration paths
CONFIG_DIR="$HOME/.claude-configs"
CONFIG_FILE="$CONFIG_DIR/config.json"
CURRENT_ENV="$CONFIG_DIR/current.env"
BACKUP_DIR="$CONFIG_DIR/backup"
HISTORY_LOG="$CONFIG_DIR/history.log"
ZSHRC_PATH="$HOME/.zshrc"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Emojis for better UX
SUCCESS="✅"
ERROR="❌"
INFO="ℹ️"
CURRENT="📍"
CONFIG="⚙️"
SWITCH="🔄"

# Initialize configuration directory and files
init_config() {
    if [[ ! -d "$CONFIG_DIR" ]]; then
        mkdir -p "$CONFIG_DIR"
        mkdir -p "$BACKUP_DIR"
        chmod 700 "$CONFIG_DIR"
        chmod 700 "$BACKUP_DIR"
    fi
    
    # Create default config if not exists
    if [[ ! -f "$CONFIG_FILE" ]]; then
        create_default_config
    fi
}

# Create default configuration from existing .zshrc
create_default_config() {
    echo "Creating default configuration..."
    
    # Backup original .zshrc
    if [[ -f "$ZSHRC_PATH" ]]; then
        cp "$ZSHRC_PATH" "$BACKUP_DIR/original-zshrc-$(date +%Y%m%d-%H%M%S)"
    fi
    
    # Extract existing configurations from .zshrc
    local anyrouter_token=""
    local anyrouter_url=""
    local zhuipu_token=""
    local zhuipu_url=""
    local current_config="zhuipu"
    
    if [[ -f "$ZSHRC_PATH" ]]; then
        # Extract anyrouter config (commented)
        anyrouter_token=$(grep "^#export ANTHROPIC_AUTH_TOKEN=sk-" "$ZSHRC_PATH" | head -1 | sed 's/^#export ANTHROPIC_AUTH_TOKEN=//' || echo "")
        anyrouter_url=$(grep "^#export ANTHROPIC_BASE_URL=https://anyrouter" "$ZSHRC_PATH" | head -1 | sed 's/^#export ANTHROPIC_BASE_URL=//' || echo "")
        
        # Extract zhuipu config (active)
        zhuipu_token=$(grep "^export ANTHROPIC_AUTH_TOKEN=" "$ZSHRC_PATH" | head -1 | sed 's/^export ANTHROPIC_AUTH_TOKEN=//' || echo "")
        zhuipu_url=$(grep "^export ANTHROPIC_BASE_URL=" "$ZSHRC_PATH" | head -1 | sed 's/^export ANTHROPIC_BASE_URL=//' || echo "")
    fi
    
    # Set defaults if not found
    [[ -z "$anyrouter_token" ]] && anyrouter_token="sk-ant-example1234567890abcdefghijklmnopqrstuvwxyz"
    [[ -z "$anyrouter_url" ]] && anyrouter_url="https://anyrouter.top"
    [[ -z "$zhuipu_token" ]] && zhuipu_token="zhipu-example-token-1234567890abcdefghij.ExampleKey"
    [[ -z "$zhuipu_url" ]] && zhuipu_url="https://open.bigmodel.cn/api/anthropic"
    
    # Create config.json
    cat > "$CONFIG_FILE" << EOF
{
  "configs": {
    "anyrouter": {
      "url": "$anyrouter_url",
      "token": "$anyrouter_token",
      "description": "AnyRouter Proxy Service",
      "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    },
    "zhuipu": {
      "url": "$zhuipu_url", 
      "token": "$zhuipu_token",
      "description": "ZhiPu AI Service",
      "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    }
  },
  "current": "$current_config",
  "last_updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    
    chmod 600 "$CONFIG_FILE"
    echo -e "${SUCCESS} Default configuration created"
}

# Get current configuration name
get_current_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        python3 -c "
import json, sys
try:
    with open('$CONFIG_FILE', 'r') as f:
        data = json.load(f)
    print(data.get('current', ''))
except:
    sys.exit(1)
"
    fi
}

# Get configuration details
get_config_details() {
    local config_name="$1"
    if [[ -f "$CONFIG_FILE" ]]; then
        python3 -c "
import json, sys
try:
    with open('$CONFIG_FILE', 'r') as f:
        data = json.load(f)
    config = data.get('configs', {}).get('$config_name', {})
    if config:
        print(f\"{config.get('url', '')}\")
        print(f\"{config.get('token', '')}\")
        print(f\"{config.get('description', '')}\")
    else:
        sys.exit(1)
except:
    sys.exit(1)
"
    fi
}

# List all configurations
list_configs() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${ERROR} No configurations found"
        return 1
    fi
    
    echo -e "${CONFIG} Available configurations:"
    echo
    
    local current=$(get_current_config)
    local counter=1
    
    python3 -c "
import json
counter = 1
with open('$CONFIG_FILE', 'r') as f:
    data = json.load(f)
configs = data.get('configs', {})
current = data.get('current', '')

for name, config in configs.items():
    icon = '🟢' if name == current else '🟡' 
    url = config.get('url', 'N/A')
    desc = config.get('description', 'No description')
    print(f'{counter}. {icon} {desc} ({name}) - {url}')
    counter += 1
" 2>/dev/null || {
        echo -e "${ERROR} Failed to read configurations"
        return 1
    }
    
    echo
    if [[ -n "$current" ]]; then
        local details=$(get_config_details "$current")
        local desc=$(echo "$details" | sed -n '3p')
        echo -e "${CURRENT} Current: ${desc} (${current})"
    fi
}

# Switch to a configuration
switch_config() {
    local target_config="$1"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${ERROR} Configuration file not found. Run 'cswitch init' first."
        return 1
    fi
    
    # Validate configuration exists
    local details=$(get_config_details "$target_config" 2>/dev/null) || {
        echo -e "${ERROR} Configuration '$target_config' not found"
        echo "Available configurations:"
        python3 -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    data = json.load(f)
configs = data.get('configs', {})
for name in configs.keys():
    print(f'  - {name}')
" 2>/dev/null
        return 1
    }
    
    local url=$(echo "$details" | sed -n '1p')
    local token=$(echo "$details" | sed -n '2p')
    local description=$(echo "$details" | sed -n '3p')
    
    # Update .zshrc file
    update_zshrc "$target_config" "$url" "$token"
    
    # Update current config in JSON
    python3 -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    data = json.load(f)
data['current'] = '$target_config'
data['last_updated'] = '$(date -u +%Y-%m-%dT%H:%M:%SZ)'
with open('$CONFIG_FILE', 'w') as f:
    json.dump(data, f, indent=2)
"
    
    # Log the switch
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Switched to: $target_config ($description)" >> "$HISTORY_LOG"
    
    # Output environment variables for eval
    echo "export ANTHROPIC_BASE_URL=\"$url\""
    echo "export ANTHROPIC_AUTH_TOKEN=\"$token\""
    echo "echo -e \"${SUCCESS} Switched to: ${description} (${target_config})\""
}

# Update .zshrc file
update_zshrc() {
    local target_config="$1" 
    local url="$2"
    local token="$3"
    
    if [[ ! -f "$ZSHRC_PATH" ]]; then
        echo -e "${ERROR} .zshrc file not found"
        return 1
    fi
    
    # Create backup
    cp "$ZSHRC_PATH" "$BACKUP_DIR/zshrc-backup-$(date +%Y%m%d-%H%M%S)"
    
    # Create temporary file
    local temp_file=$(mktemp)
    
    # Remove all existing ANTHROPIC configurations cleanly (both #export and # export patterns)
    sed -E '/^[[:space:]]*#[[:space:]]*export ANTHROPIC_(AUTH_TOKEN|BASE_URL)=/d; /^[[:space:]]*export ANTHROPIC_(AUTH_TOKEN|BASE_URL)=/d; /^[[:space:]]*#export ANTHROPIC_(AUTH_TOKEN|BASE_URL)=/d; /^[[:space:]]*#.*Claude Configuration Switcher/d' "$ZSHRC_PATH" > "$temp_file"
    
    # Add new configuration
    cat >> "$temp_file" << EOF

# Claude Configuration Switcher - Current Active Configuration
export ANTHROPIC_AUTH_TOKEN=$token
export ANTHROPIC_BASE_URL=$url
EOF
    
    # Replace original file if successful
    if [[ $? -eq 0 ]]; then
        mv "$temp_file" "$ZSHRC_PATH"
        echo -e "${SUCCESS} .zshrc updated"
    else
        rm -f "$temp_file"
        echo -e "${ERROR} Failed to update .zshrc"
        return 1
    fi
}

# Show current status
show_status() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${ERROR} No configuration found. Run 'cswitch init' first."
        return 1
    fi
    
    local current=$(get_current_config)
    if [[ -z "$current" ]]; then
        echo -e "${ERROR} No current configuration set"
        return 1
    fi
    
    local details=$(get_config_details "$current")
    local url=$(echo "$details" | sed -n '1p')
    local token=$(echo "$details" | sed -n '2p')
    local description=$(echo "$details" | sed -n '3p')
    
    # Mask token for security
    local masked_token="${token:0:12}***${token: -2}"
    
    echo -e "${CURRENT} Current Configuration: ${GREEN}${description} (${current})${NC}"
    echo -e "${INFO} Base URL: ${CYAN}${url}${NC}"
    echo -e "${INFO} Token: ${YELLOW}${masked_token}${NC}"
    
    if [[ -f "$HISTORY_LOG" ]]; then
        local last_switch=$(tail -1 "$HISTORY_LOG" 2>/dev/null | cut -d' ' -f1-2)
        if [[ -n "$last_switch" ]]; then
            echo -e "${INFO} Last switched: ${last_switch}"
        fi
    fi
}

# Interactive menu
show_interactive_menu() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${ERROR} No configurations found. Run 'cswitch init' first."
        return 1
    fi
    
    echo -e "${SUCCESS} Claude Configuration Switcher"
    echo
    
    list_configs
    echo
    
    # Get configuration names
    local configs=($(python3 -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    data = json.load(f)
for name in data.get('configs', {}).keys():
    print(name)
" 2>/dev/null))
    
    local count=${#configs[@]}
    
    if [[ $count -eq 0 ]]; then
        echo -e "${ERROR} No configurations available"
        return 1
    fi
    
    echo -n "Choose [1-$count] or [q]uit: "
    read -r choice
    
    case "$choice" in
        [qQ]|quit|exit)
            echo "Cancelled"
            return 0
            ;;
        [1-9]*)
            if [[ "$choice" -gt 0 && "$choice" -le $count ]]; then
                local selected_config="${configs[$((choice-1))]}"
                switch_config "$selected_config"
            else
                echo -e "${ERROR} Invalid choice: $choice"
                return 1
            fi
            ;;
        *)
            echo -e "${ERROR} Invalid choice: $choice"
            return 1
            ;;
    esac
}

# Add new configuration
add_config() {
    local alias="$1"
    local url="$2" 
    local token="$3"
    local description="$4"
    
    if [[ -z "$alias" || -z "$url" || -z "$token" ]]; then
        echo "Usage: cswitch add <alias> <url> <token> [description]"
        echo
        echo "Example:"
        echo "  cswitch add official \"https://api.anthropic.com\" \"sk-ant-xxxxx\" \"Claude Official API\""
        return 1
    fi
    
    [[ -z "$description" ]] && description="Custom Configuration"
    
    init_config
    
    # Check if alias already exists
    if get_config_details "$alias" >/dev/null 2>&1; then
        echo -e "${ERROR} Configuration '$alias' already exists"
        return 1
    fi
    
    # Add to config file
    python3 -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    data = json.load(f)

data['configs']['$alias'] = {
    'url': '$url',
    'token': '$token', 
    'description': '$description',
    'created': '$(date -u +%Y-%m-%dT%H:%M:%SZ)'
}

data['last_updated'] = '$(date -u +%Y-%m-%dT%H:%M:%SZ)'

with open('$CONFIG_FILE', 'w') as f:
    json.dump(data, f, indent=2)
"
    
    echo -e "${SUCCESS} Configuration '$alias' added successfully"
    echo -e "${INFO} Use 'cswitch $alias' to switch to this configuration"
}

# Remove configuration
remove_config() {
    local alias="$1"
    
    if [[ -z "$alias" ]]; then
        echo "Usage: cswitch remove <alias>"
        return 1
    fi
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${ERROR} No configurations found"
        return 1
    fi
    
    # Check if configuration exists
    if ! get_config_details "$alias" >/dev/null 2>&1; then
        echo -e "${ERROR} Configuration '$alias' not found"
        return 1
    fi
    
    # Check if it's the current configuration
    local current=$(get_current_config)
    if [[ "$current" == "$alias" ]]; then
        echo -e "${ERROR} Cannot remove current active configuration '$alias'"
        echo "Switch to another configuration first"
        return 1
    fi
    
    echo -n "Are you sure you want to remove '$alias' configuration? [y/N]: "
    read -r confirm
    
    case "$confirm" in
        [yY]|[yY][eE][sS])
            python3 -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    data = json.load(f)

if '$alias' in data.get('configs', {}):
    del data['configs']['$alias']
    data['last_updated'] = '$(date -u +%Y-%m-%dT%H:%M:%SZ)'
    
    with open('$CONFIG_FILE', 'w') as f:
        json.dump(data, f, indent=2)
    print('Configuration removed successfully')
else:
    print('Configuration not found')
"
            echo -e "${SUCCESS} Configuration '$alias' removed"
            ;;
        *)
            echo "Cancelled"
            ;;
    esac
}

# Show usage help
show_help() {
    cat << 'EOF'
Claude Configuration Switcher v1.0.0

A tool for managing multiple Claude API configurations

USAGE:
    cswitch [COMMAND] [OPTIONS]

COMMANDS:
    (no args)              Show interactive menu
    <alias>                Switch to configuration by alias
    status                 Show current configuration
    list                   List all configurations
    add <alias> <url> <token> [desc]  Add new configuration
    remove <alias>         Remove configuration
    init                   Initialize configuration
    help                   Show this help

EXAMPLES:
    cswitch                           # Interactive menu
    cswitch anyrouter                 # Switch to anyrouter config
    cswitch zhuipu                    # Switch to zhuipu config
    cswitch status                    # Show current config
    cswitch list                      # List all configs
    cswitch add official "https://api.anthropic.com" "sk-ant-xxx" "Official API"

CONFIGURATION:
    Config file: ~/.claude-configs/config.json
    Backup dir:  ~/.claude-configs/backup/
    
For more information, see the documentation in the project directory.
EOF
}

# Main function
main() {
    # Initialize if needed
    init_config
    
    case "${1:-}" in
        "")
            show_interactive_menu
            ;;
        "status")
            show_status
            ;;
        "list")
            list_configs
            ;;
        "add")
            shift
            add_config "$@"
            ;;
        "remove")
            shift
            remove_config "$@"
            ;;
        "init")
            create_default_config
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            # Try to switch to the specified configuration
            switch_config "$1"
            ;;
    esac
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly
    main "$@"
fi
