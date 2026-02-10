# Dedicated-Server-Utilities
## CS2Server/cs2watchdog.sh
### To make use of the script, it is important that you first ensure you know your:
- steamcmd installation path
- cs2 server installation path
- cs2 server start script path

### Installation & dependencies for base functionality
* Step 1: install metamod on your server following the documentation correctly https://cs2.poggu.me/metamod/installation/
* Step 2: specify directory vars for the script to run correctly (mandatory $CS2DIR, $STEAMCMD, and $START_SCRIPT)
* Step 3: install the screen utility (sudo apt update && sudo apt install screen)
* Step 4: make the script executable (sudo chmod +x cs2watchdog.sh)
* Step 5: edit your crontab (crontab -e) to execute the script and log any errors if desired. An example is located in CS2Server/

### Specify log output.
- It would also be wise to specify the LOG_DIR and name of the LOG ($LOG_DIR/nameoflog.log) if you wish to change it.
- An example of correct installation/error free log output is as follows: <img width="1261" height="217" alt="image" src="https://github.com/user-attachments/assets/e0d23c99-2090-43c1-8471-afb25a60008e" />

### Why Screen Sessions?
- Screen sessions allow for retaining full control over your terminal at all times, without being inturrupted by processes that would normally run in the forground, like steamcmd updates.
* Use screen -ls to list your current screens!
* Use screen -r (screen name) to attach to that screen.
* Use CTRL + A, then D to detach from a screen and return to your terminal.

* An example of using screens to interact with the server processes, in the order described: <img width="864" height="166" alt="image" src="https://github.com/user-attachments/assets/d95ded78-72ac-4fc2-8978-3e8cea09fd78" />
