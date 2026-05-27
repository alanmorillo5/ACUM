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
