#!/usr/bin/env bash

# AUCM Database Controller
# Manages the command list for the Auto-Update CLI Manager

# Path to the database file (absolute path)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_FILE="$SCRIPT_DIR/../data/commands.db"
STATE_FILE="$SCRIPT_DIR/../data/.aucm_state"
LAST_RUN_FILE="$SCRIPT_DIR/../data/.last_run"
INTERVAL_FILE="$SCRIPT_DIR/../data/.aucm_interval"
INTERVAL_STR_FILE="$SCRIPT_DIR/../data/.aucm_interval_str"

# Ensure data directory and default state exist
mkdir -p "$(dirname "$DB_FILE")"
touch "$DB_FILE"
if [[ ! -f "$STATE_FILE" ]]; then
    echo "OFF" > "$STATE_FILE"
fi
if [[ ! -f "$INTERVAL_FILE" ]]; then
    echo "604800" > "$INTERVAL_FILE" # 7 days
fi
if [[ ! -f "$INTERVAL_STR_FILE" ]]; then
    echo "7 days" > "$INTERVAL_STR_FILE"
fi

# List all stored commands
list_commands() {
    if [[ ! -s "$DB_FILE" ]]; then
        echo "No commands stored."
        return
    fi
    cat "$DB_FILE"
}

# Add command(s) to the database
# Usage: add_command <command_string>
add_command() {
    local raw_input="$1"
    
    # Split by comma
    IFS=',' read -ra cmd_array <<< "$raw_input"
    
    for cmd in "${cmd_array[@]}"; do
        # Trim whitespace
        cmd=$(echo "$cmd" | xargs)
        
        if [[ -z "$cmd" ]]; then
            continue
        fi

        # Injection check: reject shell metacharacters
        # This prevents ; | & < > $ ` ( ) \ and prevents arbitrary subshells or chained commands
        local injection_pattern='[;&|<>$`()\\]'
        if [[ "$cmd" =~ $injection_pattern ]]; then
            echo "Error: '$cmd' contains invalid characters (injection attempt detected)."
            continue
        fi

        # Smart Dependency Parsing: If single word, attempt to resolve package manager command
        if [[ ! "$cmd" =~ [[:space:]] ]]; then
            if ! command -v "$cmd" >/dev/null 2>&1; then
                echo "Error: Dependency '$cmd' not found in PATH."
                continue
            fi
            
            local resolved=""
            local exec_path
            exec_path=$(command -v "$cmd")
            
            # Determine package manager based on environment/path
            if [[ "$exec_path" == *"node_modules"* || "$exec_path" == *".nvm"* ]] && command -v npm >/dev/null 2>&1; then
                resolved="npm update -g $cmd"
            elif command -v brew >/dev/null 2>&1; then
                resolved="brew upgrade $cmd"
            elif command -v apt-get >/dev/null 2>&1; then
                # Use -y to ensure background daemon doesn't block on interactive prompts
                resolved="sudo apt-get --only-upgrade -y install $cmd"
            fi
            
            if [[ -n "$resolved" ]]; then
                echo "Smart parser resolved '$cmd' to: $resolved"
                cmd="$resolved"
            else
                echo "Note: No automatic wrapper found for '$cmd'. Storing as raw command."
            fi
        fi

        # Dry-run validation: Check if the first word is a valid executable
        local base_cmd
        base_cmd=$(echo "$cmd" | awk '{print $1}')
        
        if ! command -v "$base_cmd" >/dev/null 2>&1; then
            echo "Error: '$base_cmd' is not a valid executable on this system."
            continue
        fi

        # Check for duplicates
        if grep -Fxq "$cmd" "$DB_FILE"; then
            echo "Command '$cmd' is already in the database."
            continue
        fi

        echo "$cmd" >> "$DB_FILE"
        echo "Added: $cmd"
    done
}

# Remove command(s) from the database
# Usage: remove_command <command_string>
remove_command() {
    local raw_input="$1"
    
    # Split by comma
    IFS=',' read -ra cmd_array <<< "$raw_input"
    
    for cmd in "${cmd_array[@]}"; do
        # Trim whitespace
        cmd=$(echo "$cmd" | xargs)
        
        if [[ -z "$cmd" ]]; then
            continue
        fi

        if grep -Fxq "$cmd" "$DB_FILE"; then
            # Use a temporary file for safety
            local temp_db
            temp_db=$(mktemp)
            grep -Fvx "$cmd" "$DB_FILE" > "$temp_db"
            mv "$temp_db" "$DB_FILE"
            echo "Removed: $cmd"
        else
            echo "Error: Command '$cmd' not found in database."
        fi
    done
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

# Set the update period using regex validation
# Usage: set_update_period "12 hours"
set_update_period() {
    local input="$1"
    # Case-insensitive regex for integer + unit
    local regex='^([0-9]+)[[:space:]]*(minutes?|mins?|hours?|hrs?|days?|months?)$'
    
    # We use shopt to make the regex match case-insensitive
    local old_nocasematch
    old_nocasematch=$(shopt -p nocasematch)
    shopt -s nocasematch
    
    if [[ ! "$input" =~ $regex ]]; then
        eval "$old_nocasematch"
        echo "Error: Invalid period format. Use e.g., '12 hours' or '3 days'."
        return 1
    fi
    
    local value="${BASH_REMATCH[1]}"
    local unit
    unit=$(echo "${BASH_REMATCH[2]}" | tr '[:upper:]' '[:lower:]')
    eval "$old_nocasematch"
    local seconds=0
    
    # Handle singular/plural nouns for integer 1
    if [[ "$value" -eq 1 ]]; then
        case "$unit" in
            minutes|mins) unit="minute" ;;
            hours|hrs) unit="hour" ;;
            days) unit="day" ;;
            months) unit="month" ;;
        esac
    else
        case "$unit" in
            minute|min) unit="minutes" ;;
            hour|hr) unit="hours" ;;
            day) unit="days" ;;
            month) unit="months" ;;
        esac
    fi
    
    case "$unit" in
        minute|minutes|min|mins) seconds=$((value * 60)) ;;
        hour|hours|hr|hrs) seconds=$((value * 3600)) ;;
        day|days) seconds=$((value * 86400)) ;;
        month|months) seconds=$((value * 2592000)) ;;
    esac
    
    echo "$seconds" > "$INTERVAL_FILE"
    echo "$value $unit" > "$INTERVAL_STR_FILE"
    echo "Update period set to $value $unit ($seconds seconds)."
    
    # Restart daemon if running to apply new interval
    local pid_file="$(dirname "$DB_FILE")/aucm.pid"
    if [[ -f "$pid_file" ]]; then
        local pid
        pid=$(cat "$pid_file")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo "Restarting daemon to apply new period..."
            stop_daemon
            start_daemon
        fi
    fi
}

# Daemon loop that runs in the background
daemon_loop() {
    local poll_rate=60 # Check state every 60 seconds
    
    while true; do
        local interval
        interval=$(cat "$INTERVAL_FILE" 2>/dev/null || echo 604800)
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

# --- CLI Dashboard ---

show_dashboard() {
    clear
    echo "========================================"
    echo "       Auto-Update CLI Manager (AUCM)   "
    echo "========================================"
    
    local state
    state=$(cat "$STATE_FILE" 2>/dev/null || echo "OFF")
    
    local count
    count=$(grep -c "^" "$DB_FILE" 2>/dev/null || echo "0")
    count=$(echo "$count" | xargs) # Trim whitespace
    
    local period
    period=$(cat "$INTERVAL_STR_FILE" 2>/dev/null || echo "7 days")
    
    local next_run_display="N/A"
    if [[ "$state" == "ON" ]]; then
        local last_run
        last_run=$(cat "$LAST_RUN_FILE" 2>/dev/null || echo 0)
        local interval
        interval=$(cat "$INTERVAL_FILE" 2>/dev/null || echo 604800)
        
        if [[ "$last_run" -eq 0 ]]; then
            next_run_display="Pending run"
        else
            local now
            now=$(date +%s)
            local next_run=$((last_run + interval))
            local time_left=$((next_run - now))
            
            if [[ $time_left -le 0 ]]; then
                next_run_display="Due now"
            else
                local d=$((time_left / 86400))
                local h=$(( (time_left % 86400) / 3600 ))
                local m=$(( (time_left % 3600) / 60 ))
                local s=$(( time_left % 60 ))
                local time_str=""
                [[ $d -gt 0 ]] && time_str+="${d}d "
                [[ $h -gt 0 ]] && time_str+="${h}h "
                [[ $m -gt 0 ]] && time_str+="${m}m "
                [[ $s -gt 0 || -z "$time_str" ]] && time_str+="${s}s"
                
                # Trim trailing space
                time_str=$(echo "$time_str" | xargs)
                next_run_display="In $time_str"
            fi
        fi
    else
        next_run_display="Paused"
    fi
    
    echo " Update Period:       $period"
    echo " Auto-Update Status:  $state"
    echo " Next Update Cycle:   $next_run_display"
    echo " Tracked Commands:    $count"
    echo "========================================"
    echo " 1. Add command(s) / dependency"
    echo " 2. Remove command(s) / dependency"
    echo " 3. Clear all commands"
    echo " 4. Toggle auto-update (ON/OFF)"
    echo " 5. Set update period"
    echo " 6. Run all updates now"
    echo " 7. Display all stored commands"
    echo " 8. Exit"
    echo "========================================"
}

main_menu() {
    while true; do
        show_dashboard
        read -p "Select an option [1-8]: " choice
        
        case $choice in
            1)
                echo "Enter the command(s) to add (e.g., 'brew upgrade node'):"
                read -p "> " input_cmd
                add_command "$input_cmd"
                read -p "Press Enter to continue..."
                ;;
            2)
                echo "Enter the exact command to remove:"
                read -p "> " input_cmd
                remove_command "$input_cmd"
                read -p "Press Enter to continue..."
                ;;
            3)
                read -p "Are you sure you want to clear all commands? (y/n): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    clear_commands
                fi
                read -p "Press Enter to continue..."
                ;;
            4)
                toggle_auto_update
                # Sync daemon with new state
                local current_state
                current_state=$(cat "$STATE_FILE" 2>/dev/null || echo "OFF")
                if [[ "$current_state" == "ON" ]]; then
                    start_daemon
                else
                    stop_daemon
                fi
                read -p "Press Enter to continue..."
                ;;
            5)
                echo "Enter the update period (e.g., '12 hours', '3 days', '1 month'):"
                read -p "> " input_period
                set_update_period "$input_period"
                read -p "Press Enter to continue..."
                ;;
            6)
                run_all_updates
                read -p "Press Enter to continue..."
                ;;
            7)
                echo "--- Stored Commands ---"
                list_commands
                echo "-----------------------"
                read -p "Press Enter to continue..."
                ;;
            8)
                echo "Exiting AUCM Dashboard."
                exit 0
                ;;
            *)
                echo "Invalid option. Please enter a number between 1 and 8."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Entry point for daemon and script execution
if [[ "$1" == "--run-daemon-loop" ]]; then
    daemon_loop
elif [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Start the interactive dashboard only if run directly, not sourced
    main_menu
fi
