# Dedicated-Server-Utilities
## CS2Server/cs2watchdog.sh
### To make use of the script, it is important that you first ensure you know your:
- 1: steamcmd installation path
- 2: cs2 server installation path
- 3: cs2 server start script path

### Installation & dependencies for base functionality
* Step 1: install metamod on your server following the documentation correctly https://cs2.poggu.me/metamod/installation/
* Step 2: specify directory vars for the script to run correctly (mandatory $CS2DIR, $STEAMCMD, and $START_SCRIPT)
* Step 3: install the screens utility (ubuntu: sudo apt update && sudo apt install screen)
* Step 4: make the script executable (sudo chmod +x cs2watchdog.sh)

### Specify log output.
- It would also be wise to specify the LOG_DIR and name of the LOG ($LOG_DIR/nameoflog.log) if you wish to change it.
