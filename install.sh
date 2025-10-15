#!/bin/bash

# Claude Configuration Switcher - Installation Script
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

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Emojis
SUCCESS="✅"
ERROR="❌"
INFO="ℹ️"
INSTALL="🚀"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="claude-switch.sh"
COMMAND_NAME="cswitch"

echo -e "${INSTALL} Claude Configuration Switcher Installation"
echo "=================================================="
echo

# Check dependencies
check_dependencies() {
    echo -e "${INFO} Checking dependencies..."
    
    local missing_deps=()
    
    # Check for Python 3
    if ! command -v python3 &> /dev/null; then
        missing_deps+=("python3")
    fi
    
    # Check for basic Unix tools
    for tool in grep sed awk; do
        if ! command -v "$tool" &> /dev/null; then
            missing_deps+=("$tool")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "${ERROR} Missing dependencies: ${missing_deps[*]}"
        echo "Please install the missing dependencies and try again."
        return 1
    fi
    
    echo -e "${SUCCESS} All dependencies satisfied"
    return 0
}

# Install the script
install_script() {
    echo -e "${INFO} Installing claude-switch script..."
    
    # Check if source script exists
    if [[ ! -f "$SCRIPT_DIR/$SCRIPT_NAME" ]]; then
        echo -e "${ERROR} Script file not found: $SCRIPT_DIR/$SCRIPT_NAME"
        return 1
    fi
    
    # Check if install directory exists and is writable
    if [[ ! -d "$INSTALL_DIR" ]]; then
        echo -e "${ERROR} Install directory does not exist: $INSTALL_DIR"
        echo "You may need to create it with: sudo mkdir -p $INSTALL_DIR"
        return 1
    fi
    
    # Check write permissions
    if [[ ! -w "$INSTALL_DIR" ]]; then
        echo -e "${YELLOW} No write permission to $INSTALL_DIR"
        echo "Installing with sudo..."
        sudo cp "$SCRIPT_DIR/$SCRIPT_NAME" "$INSTALL_DIR/$COMMAND_NAME"
        sudo chmod +x "$INSTALL_DIR/$COMMAND_NAME"
    else
        cp "$SCRIPT_DIR/$SCRIPT_NAME" "$INSTALL_DIR/$COMMAND_NAME"
        chmod +x "$INSTALL_DIR/$COMMAND_NAME"
    fi
    
    echo -e "${SUCCESS} Script installed to $INSTALL_DIR/$COMMAND_NAME"
}

# Setup shell integration
setup_shell_integration() {
    echo -e "${INFO} Setting up shell integration..."
    
    local shell_rc=""
    local shell_name=""
    
    # Detect shell
    if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == *"zsh"* ]]; then
        shell_rc="$HOME/.zshrc"
        shell_name="zsh"
    elif [[ -n "${BASH_VERSION:-}" ]] || [[ "$SHELL" == *"bash"* ]]; then
        shell_rc="$HOME/.bashrc"
        shell_name="bash"
    else
        echo -e "${YELLOW} Could not detect shell type. Manual setup required."
        return 0
    fi
    
    echo "Detected shell: $shell_name"
    echo "Shell RC file: $shell_rc"
    
    # Ask user for integration method
    echo
    echo "Choose integration method:"
    echo "1. Function mode (recommended) - Add shell function to $shell_rc"
    echo "2. Alias mode - Add alias to $shell_rc"
    echo "3. Manual mode - No automatic integration"
    echo
    read -p "Choose [1-3]: " choice
    
    case "$choice" in
        1)
            setup_function_mode "$shell_rc" "$shell_name"
            ;;
        2)
            setup_alias_mode "$shell_rc"
            ;;
        3)
            echo -e "${INFO} Manual mode selected. You can call the script with: $COMMAND_NAME"
            ;;
        *)
            echo -e "${ERROR} Invalid choice. Using manual mode."
            ;;
    esac
}

# Setup function mode
setup_function_mode() {
    local shell_rc="$1"
    local shell_name="$2"
    
    echo -e "${INFO} Setting up function mode..."
    
    # Check if function already exists
    if grep -q "^cswitch()" "$shell_rc" 2>/dev/null; then
        echo -e "${YELLOW} Function already exists in $shell_rc"
        read -p "Replace existing function? [y/N]: " replace
        if [[ ! "$replace" =~ ^[Yy]$ ]]; then
            echo "Keeping existing function"
            return 0
        fi
        
        # Remove existing function
        sed -i.bak '/^cswitch()/,/^}/d' "$shell_rc"
    fi
    
    # Add function to shell RC
    cat >> "$shell_rc" << EOF

# Claude Configuration Switcher Function
cswitch() {
    local result
    local exit_code
    
    # Call the actual script and capture output and exit code
    result=\$($INSTALL_DIR/$COMMAND_NAME "\$@" 2>&1)
    exit_code=\$?
    
    if [[ \$exit_code -eq 0 && "\$*" != "status" && "\$*" != "list" && "\$*" != "help" && "\$*" != "" ]]; then
        # If it's a switch command, evaluate the output to set environment variables
        if [[ "\$result" == *"export ANTHROPIC_"* ]]; then
            eval "\$result"
        else
            echo "\$result"
        fi
    else
        echo "\$result"
        return \$exit_code
    fi
}
EOF
    
    echo -e "${SUCCESS} Function added to $shell_rc"
    echo -e "${INFO} Please run: source $shell_rc"
    echo -e "${INFO} Or restart your terminal to use the function"
}

# Setup alias mode
setup_alias_mode() {
    local shell_rc="$1"
    
    echo -e "${INFO} Setting up alias mode..."
    
    # Check if alias already exists
    if grep -q "alias cswitch=" "$shell_rc" 2>/dev/null; then
        echo -e "${YELLOW} Alias already exists in $shell_rc"
        read -p "Replace existing alias? [y/N]: " replace
        if [[ ! "$replace" =~ ^[Yy]$ ]]; then
            echo "Keeping existing alias"
            return 0
        fi
        
        # Remove existing alias
        sed -i.bak '/alias cswitch=/d' "$shell_rc"
    fi
    
    # Add alias to shell RC
    cat >> "$shell_rc" << EOF

# Claude Configuration Switcher Alias
alias cswitch='eval \$($INSTALL_DIR/$COMMAND_NAME "\$@")'
EOF
    
    echo -e "${SUCCESS} Alias added to $shell_rc"
    echo -e "${INFO} Please run: source $shell_rc"
    echo -e "${INFO} Or restart your terminal to use the alias"
}

# Initialize configuration
init_configuration() {
    echo -e "${INFO} Initializing configuration..."
    
    # Run the script to create initial config
    if command -v "$COMMAND_NAME" &> /dev/null; then
        "$COMMAND_NAME" init
        echo -e "${SUCCESS} Configuration initialized"
    else
        echo -e "${ERROR} Command '$COMMAND_NAME' not found in PATH"
        echo "You may need to restart your terminal or source your shell RC file"
        return 1
    fi
}

# Verify installation
verify_installation() {
    echo -e "${INFO} Verifying installation..."
    
    # Check if command is available
    if ! command -v "$COMMAND_NAME" &> /dev/null; then
        echo -e "${ERROR} Command '$COMMAND_NAME' not found"
        echo "Installation may have failed"
        return 1
    fi
    
    echo -e "${SUCCESS} Installation verified"
    echo
    echo "Installation complete! 🎉"
    echo
    echo "Usage:"
    echo "  cswitch              # Interactive menu"
    echo "  cswitch anyrouter    # Switch to anyrouter config"
    echo "  cswitch zhuipu       # Switch to zhuipu config"
    echo "  cswitch status       # Show current config"
    echo "  cswitch help         # Show help"
    echo
    echo "Configuration files are stored in: ~/.claude-configs/"
    echo
}

# Uninstall function
uninstall() {
    echo -e "${INFO} Uninstalling Claude Configuration Switcher..."
    
    # Remove script
    if [[ -f "$INSTALL_DIR/$COMMAND_NAME" ]]; then
        if [[ -w "$INSTALL_DIR" ]]; then
            rm -f "$INSTALL_DIR/$COMMAND_NAME"
        else
            sudo rm -f "$INSTALL_DIR/$COMMAND_NAME"
        fi
        echo -e "${SUCCESS} Script removed from $INSTALL_DIR"
    fi
    
    # Ask about removing configuration
    read -p "Remove configuration files (~/.claude-configs/)? [y/N]: " remove_config
    if [[ "$remove_config" =~ ^[Yy]$ ]]; then
        rm -rf "$HOME/.claude-configs"
        echo -e "${SUCCESS} Configuration files removed"
    fi
    
    # Ask about removing shell integration
    for rc_file in "$HOME/.zshrc" "$HOME/.bashrc"; do
        if [[ -f "$rc_file" ]] && grep -q "cswitch" "$rc_file"; then
            read -p "Remove shell integration from $(basename "$rc_file")? [y/N]: " remove_shell
            if [[ "$remove_shell" =~ ^[Yy]$ ]]; then
                # Create backup
                cp "$rc_file" "$rc_file.backup.$(date +%Y%m%d-%H%M%S)"
                
                # Remove function and alias
                sed -i.tmp '/^# Claude Configuration Switcher/,/^}/d' "$rc_file"
                sed -i.tmp '/alias cswitch=/d' "$rc_file"
                rm -f "$rc_file.tmp"
                
                echo -e "${SUCCESS} Shell integration removed from $rc_file"
            fi
        fi
    done
    
    echo -e "${SUCCESS} Uninstallation complete"
}

# Main installation function
main() {
    case "${1:-install}" in
        "install")
            if ! check_dependencies; then
                exit 1
            fi
            
            if ! install_script; then
                exit 1
            fi
            
            setup_shell_integration
            
            # Only initialize if script is available
            if command -v "$COMMAND_NAME" &> /dev/null 2>&1; then
                init_configuration
            fi
            
            verify_installation
            ;;
        "uninstall")
            uninstall
            ;;
        "check-deps"|"check")
            check_dependencies
            ;;
        "help"|"-h"|"--help")
            echo "Claude Configuration Switcher Installation Script"
            echo
            echo "Usage:"
            echo "  ./install.sh [install]     # Install the tool (default)"
            echo "  ./install.sh uninstall     # Uninstall the tool"
            echo "  ./install.sh check-deps    # Check dependencies only"
            echo "  ./install.sh help          # Show this help"
            ;;
        *)
            echo -e "${ERROR} Unknown command: $1"
            echo "Use './install.sh help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
