# AUCM - Auto-Update CLI Manager

AUCM is a simple, friendly tool designed to help you keep your computer's software up to date automatically. It runs in the background and follows a schedule you set, so you don't have to remember to run update commands manually.

## 🚀 Quick Start

1. **Open your Terminal.**
2. **Navigate to the AUCM folder.**
3. **Run the manager** by typing this command and pressing Enter:
   ```bash
   bash src/aucm.sh
   ```

---

## 🖥️ How to Use the Dashboard

When you run the script, you will see a menu with numbers. Just type a number and press **Enter** to choose an option:

### 1. Add command(s) / dependency
This is where you tell AUCM what to keep updated. 
- **Simple Way:** Just type the name of a tool (like `node`, `wget`, or `git`). AUCM will try to figure out the best way to update it for you!
- **Expert Way:** You can type a full command like `brew upgrade node`.
- **Bulk Way:** You can add multiple things at once by separating them with commas (e.g., `node, git, wget`).

### 2. Remove command(s) / dependency
Type the name or command you want to stop updating. You can also use commas here to remove many at once.

### 3. Clear all commands
This removes everything from your list. Don't worry, it will ask for your confirmation first!

### 4. Toggle auto-update (ON/OFF)
This is the "Master Switch." 
- When **ON**, AUCM will run your updates in the background automatically.
- When **OFF**, the background worker will pause and do nothing.

### 5. Set update period
Decide how often you want updates to run. You can type things like `12 hours`, `3 days`, or `1 month`. AUCM will handle the math!

### 6. Run all updates now
If you don't want to wait for the schedule, choose this to run every update in your list immediately.

### 7. Display all stored commands
Shows you a list of everything AUCM is currently tracking for you.

### 8. Exit
Closes the dashboard. If your Auto-Update is **ON**, it will continue working in the background even after you exit!

---

## ❓ Common Questions

**How do I know when the next update will happen?**
The home screen shows a "Next Update Cycle" timer. It will tell you exactly how many days, hours, or minutes are left.

**Does this work on my computer?**
If you are using a Mac or a Linux computer (like Ubuntu), yes!

**Is it safe?**
Yes. AUCM checks every command before adding it to make sure it's a real program and prevents "hidden" commands from being added maliciously.

---
