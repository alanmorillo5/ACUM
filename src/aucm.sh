#!/usr/bin/env bash

# AUCM Database Controller
# Manages the command list for the Auto-Update CLI Manager

# Path to the database file (absolute path)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_FILE="$SCRIPT_DIR/../data/commands.db"
STATE_FILE="$SCRIPT_DIR/../data/.aucm_state"
LAST_RUN_FILE="$SCRIPT_DIR/../data/.last_run"

# Ensure data directory and default state exist
mkdir -p "$(dirname "$DB_FILE")"
touch "$DB_FILE"
if [[ ! -f "$STATE_FILE" ]]; then
    echo "OFF" > "$STATE_FILE"
fi

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

# Run all updates stored in the database
run_all_updates() {
    if [[ ! -s "$DB_FILE" ]]; then
        echo "No commands to run."
        return 0
    fi

    echo "--- Starting Update Sequence ---"
    local total_commands
    total_commands=$(wc -l < "$DB_FILE" | xargs)
    local current=0

    while IFS= read -r cmd; do
        current=$((current + 1))
        echo "[$current/$total_commands] Executing: $cmd"
        
        # Execute the command
        if bash -c "$cmd"; then
            echo "Success: $cmd"
        else
            echo "Error: Command failed with exit code $?: $cmd"
        fi
        echo "--------------------------------"
    done < "$DB_FILE"

    # Record last run time
    date +%s > "$LAST_RUN_FILE"
    echo "--- Update Sequence Complete ---"
}

# Toggle auto-update ON/OFF
toggle_auto_update() {
    local current_state
    current_state=$(cat "$STATE_FILE" 2>/dev/null || echo "OFF")
    
    if [[ "$current_state" == "ON" ]]; then
        echo "OFF" > "$STATE_FILE"
        echo "Auto-update toggled OFF."
    else
        echo "ON" > "$STATE_FILE"
        echo "Auto-update toggled ON."
    fi
}

# Daemon loop that runs in the background
daemon_loop() {
    # Default interval: 7 days in seconds (604800)
    local interval=604800
    local poll_rate=60 # Check state every 60 seconds
    
    while true; do
        local state
        state=$(cat "$STATE_FILE" 2>/dev/null || echo "OFF")
        
        if [[ "$state" == "ON" ]]; then
            local now
            now=$(date +%s)
            local last_run
            last_run=$(cat "$LAST_RUN_FILE" 2>/dev/null || echo 0)
            local elapsed=$((now - last_run))
            
            if [[ $elapsed -ge $interval ]]; then
                run_all_updates >> "$(dirname "$DB_FILE")/daemon.log" 2>&1
            fi
        fi
        
        sleep "$poll_rate"
    done
}

# Start the background daemon
start_daemon() {
    local pid_file="$(dirname "$DB_FILE")/aucm.pid"
    
    if [[ -f "$pid_file" ]]; then
        local pid
        pid=$(cat "$pid_file")
        if ps -p "$pid" > /dev/null; then
            echo "Daemon is already running (PID: $pid)."
            return 1
        fi
    fi

    echo "Starting background daemon..."
    nohup bash "$0" --run-daemon-loop > /dev/null 2>&1 &
    echo $! > "$pid_file"
    echo "Daemon started (PID: $(cat "$pid_file"))."
}

# Stop the background daemon
stop_daemon() {
    local pid_file="$(dirname "$DB_FILE")/aucm.pid"
    
    if [[ ! -f "$pid_file" ]]; then
        echo "Daemon is not running (no PID file found)."
        return 1
    fi

    local pid
    pid=$(cat "$pid_file")
    if ps -p "$pid" > /dev/null; then
        echo "Stopping daemon (PID: $pid)..."
        kill "$pid"
        rm "$pid_file"
        echo "Daemon stopped."
    else
        echo "Daemon is not running (PID $pid not found). Cleaning up PID file."
        rm "$pid_file"
    fi
}

# Entry point for daemon and script execution
if [[ "$1" == "--run-daemon-loop" ]]; then
    daemon_loop
fi
