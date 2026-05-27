#!/usr/bin/env bash

# AUCM Database Controller
# Manages the command list for the Auto-Update CLI Manager

# Path to the database file
DB_FILE="$(dirname "$0")/../data/commands.db"

# Ensure data directory exists
mkdir -p "$(dirname "$DB_FILE")"
touch "$DB_FILE"

# List all stored commands
list_commands() {
    if [[ ! -s "$DB_FILE" ]]; then
        echo "No commands stored."
        return
    fi
    cat "$DB_FILE"
}

# Add a command to the database
# Usage: add_command <command_string>
add_command() {
    local cmd="$1"
    
    if [[ -z "$cmd" ]]; then
        echo "Error: Command cannot be empty."
        return 1
    fi

    # Dry-run validation: Check if the first word is a valid executable
    local base_cmd
    base_cmd=$(echo "$cmd" | awk '{print $1}')
    
    if ! command -v "$base_cmd" >/dev/null 2>&1; then
        echo "Error: '$base_cmd' is not a valid executable on this system."
        return 1
    fi

    # Check for duplicates
    if grep -Fxq "$cmd" "$DB_FILE"; then
        echo "Command '$cmd' is already in the database."
        return 0
    fi

    echo "$cmd" >> "$DB_FILE"
    echo "Added: $cmd"
}

# Remove a command from the database
# Usage: remove_command <command_string>
remove_command() {
    local cmd="$1"
    
    if grep -Fxq "$cmd" "$DB_FILE"; then
        # Use a temporary file for safety
        local temp_db
        temp_db=$(mktemp)
        grep -Fvx "$cmd" "$DB_FILE" > "$temp_db"
        mv "$temp_db" "$DB_FILE"
        echo "Removed: $cmd"
    else
        echo "Error: Command '$cmd' not found in database."
        return 1
    fi
}

# Clear all commands
clear_commands() {
    > "$DB_FILE"
    echo "All commands cleared."
}
