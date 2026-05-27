# Tasks:

## Task 3 - Command Database
- Brief: Create a list of shell commands that can be run in the CLI and store it in a lightweight database.
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

## Task 9 - Edge Cases
- Brief: Ensure invalid commands are tested before adding to the database, and handle other edge cases such as empty strings and injections.
- What Gemini proposed: Bulk processing, gracefully handle whitespace and empty strings, prevent injection using regex.
- What I changed before approving: Remove bulk processing, will get to that later.
- Verification: Ran the dashboard and tried to add several malicious and invalid commands.
- One thing I learned: The AI tried to test by adding an exteremely risky command, so don't always trust the tests.

## Task 10 - Multiple Commands
- Brief: Allow multiple commands to be added/removed in a single request by splitting commands by an appropriate delimeter.
- What Gemini proposed: Separate by comma, refector add_command and remove_command to iterate over a list of strings.
- What I changed before approving: Fail invalid commands but allow others to pass.
- Verification: Ran add_command with multiple commands (valid and/or invalid) and ensure only valid ones pass.
- One thing I learned: I need to work with AI to consider everything.

## Task 11 - Time Parsing
- Brief: Inside of setting update period, allow input of an integer followed by minutes, hours, days, or months (use regex).
- What Gemini proposed: Add unit and value states for time, add frontend option to set time period and its corresponding backend function. Update daemon loop and display.
What I changed before approving: don't forget to use singular nouns for the integer 1, and restart the daemon after updating period if necessary.
- Verification: Run the new update_period function on frontend and backend to ensure time parsing works.
- One thing I learned: AI can effectively run tests and correct it's own mistakes.

## Task 12 - Elastic inputs
- Brief: If possible, allow input of dependency names only and try to run it with different structures (eg. brew upgrade _, _ update, etc.).
- What Gemini proposed: Detect for single word, check if dependency is installed, then run through a couple of common dependencies. If one can resolve, add it to the list.
- What I changed before approving: Nothing.
- Verification: Add single line commands and verify that they either find an upgrade command or pass naked. Ensure everything else works.
- One thing I learned: AI knows a lot more features then I do.
