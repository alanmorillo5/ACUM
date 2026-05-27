# Project: Auto-Update CLI Manager (AUCM)

## 1. Project Overview
A highly configurable, UNIX-compatible shell utility that provides a Command Line Interface (CLI) dashboard for managing and scheduling dependency updates. The tool runs seamlessly in the background, updating specified packages or running raw commands at user-defined intervals. 

## 2. Core Architecture & Tech Stack
* **Language:** Bash/Zsh (POSIX compliant where possible, utilizing standard UNIX utilities like `awk`, `sed`, `grep`).
* **Storage database:** Lightweight local flat-file database (e.g., `~/.config/aucm/commands.db`) or `sqlite3` to store command strings, ensuring maximum compatibility without heavy dependencies.
* **Background Execution:** A detached daemon process (`nohup` with a `while/sleep` loop) or native scheduler integration, capable of reading state from a configuration file to toggle execution.
* **Target Environments:** UNIX-based systems, specifically optimized to handle environments running macOS (`brew`) or Ubuntu Linux (`apt`).

## 3. Initialization & Default States
* **Default Update Period:** 7 days.
* **Default Command List:** Empty.
* **Initial State:** Auto-update toggle set to `OFF`.
* **Home Screen Display:** Upon script execution, the dashboard must display the current update period, the status of the auto-update toggle (ON/OFF), the number of tracked dependencies, and the estimated next update cycle (if ON).

## 4. CLI Dashboard Menu (Front-End)
The interactive interface will use standard standard input (stdin) to capture numbers corresponding to the following actions:
1. **Add command(s) / dependency**
2. **Remove command(s) / dependency**
3. **Clear all commands**
4. **Toggle auto-update (ON/OFF)**
5. **Set update period**
6. **Run all updates now**
7. **Display all stored commands**
8. **Exit**

## 5. Feature Specifications & Edge Cases

### Command Management & Smart Resolution
* **Bulk Processing:** The input parser must accept multiple commands or package names separated by commas or newlines (e.g., `node, python3, rustc`).
* **Smart Dependency Parsing:** If a user inputs a single word instead of a full command (e.g., `wget`), the script will attempt to resolve and build the command using the system's package manager. It will cycle through:
  * `brew upgrade <dependency>`
  * `sudo apt-get --only-upgrade install <dependency>`
  * `npm update -g <dependency>`
* **Validation & Security:** Before writing to the database, inputs must be sanitized. 
  * Reject empty strings.
  * Neutralize command injection attempts if the input is flagged strictly as a package name.
  * Run a "dry-run" test (`command -v` or `type`) to verify the executable exists before committing it to the database.

### Time Parsing & Regex
* **Period Input:** When adjusting the update period (Menu Option 5), the script will accept user input matching the regex pattern: `^[0-9]+\s*(minutes?|mins?|hours?|hrs?|days?|months?)$` (case-insensitive).
* **Conversion:** The script will convert this parsed string into seconds to feed into the background sleep cycle or cron equivalent.

### Background Toggle Mechanism
* The auto-update toggle writes a boolean flag to a lightweight `.aucm_state` file.
* The background daemon periodically checks this flag. If `ON`, it proceeds with the execution loop; if `OFF`, it pauses execution without killing the daemon process.

## 6. Project Scaffold & Development Tasks
1. **Initialize Git:** `git init`, set remote, and verify `git status`.
2. **Scaffold Repo:** Create `GEMINI.md` (this file), `src/aucm.sh`, and `data/` directories.
3. **Build DB Controller:** Functions for read/write/delete operations on the command list.
4. **Build Execution Engine:** Function to iterate over the DB and execute sequentially.
5. **Implement Daemon/Scheduler:** Develop the background execution script and toggle logic.
6. **Build UI & Input Loop:** Construct the 1-8 menu dashboard and connect to functions.
7. **Implement Smart Parsers:** Regex time conversion and package manager command guessing.
8. **Write Documentation:** Create a zero-assumption `README.md` containing a quick-start guide, installation steps, and usage examples for non-technical users.
