# Tasks:

## Task 3 - Command Database
- Breif: Create a list of shell commands that can be run in the CLI and store it in a lightweight database.
- What Gemini proposed: Flat-file database with functions add_command, list_commands, and remove_commands
- What I changed before approving: Nothing
- Verification: Developed bash script to test all commands with echo statements. Worked perfectly.
- One thing I learned: AI is getting really good at pure development

## Task 4 - Execute Commands
- Brief: Develop a script that can take all of the stored commands and run them in the CLI.
- What Gemini proposed: New function run_all_updates, running each command if not empty and reporting any errors.
- What I changed before approving: Nothing
- Verification: Added multiple valid and invald commands into the database before running the new script.
- One thing I learned: AI's tests are actually very effective.

## Task 5 - Background Execution
- Brief: Modify the script so that it can run as a background feature and auto-execute in set periods of time.
- What Gemini proposed: Manage states with global variables, Add time parsing logic, implement background daemon, add cli entry points
- What I changed before approving: remove time parsing logic and background daemon. Only focus on on and off functions for now.
- Verification: Ran the daemon with an echo command and check the daemon logs. Killed daemon with stop script
- One thing I learned: AI sometimes forgets that something doesn't work.

## Task 6 - Daemon Toggle
- Brief: Add a toggle to turn the auto-update script on and off.
- What Gemini proposed: Add a state file to track daemon state, add a script that toggles daemon on and off.
- What I changed before approving: Nothing.
- Verification: Tested toggle with active echo statements to check. Kill terminal and retest to ensure state preservation.
- One thing I learned: Need to start killing the terminal to test if states preserve.

## Task 7/8 - Frontend
- Brief: Add a front-end CLI dashboard with an initial menu, bound to numbers: add command, remove command, clear all commands, toggle auto-update, set update period, run all updates once, display all commands, exit. Add requests for each menu option.
- What Gemini proposed: Adding a dashboard with everything I asked EXCEPT period updates. Will implement later.
- What I changed before approving: Nothing.
- Verification: Ran the dashboard myself and tested each feature.
- One thing I learned: AI is very effective at frontend development.

