#!/usr/bin/env bash

#auto-detach into a dedicated screen session so this never takes over a terminal.
# and prevent recursion with CS2WATCHDOG_NO_DETACH.
if [ "${CS2WATCHDOG_NO_DETACH:-0}" -ne 1 ]; then
  #check for old watchdog session and close if necessary
  if screen -list 2>/dev/null | grep -qE "[.]cs2watchdog[[:space:]]"; then
    screen -S cs2watchdog -X quit >/dev/null 2>&1 || true
    sleep 1
  fi
  screen -dmS cs2watchdog bash -lc "CS2WATCHDOG_NO_DETACH=1 '$0'"
  exit 0
fi

set -euo pipefail

#######################################################
###### CHANGE THIS IF YOU ARE USING THIS SCRIPT! ######
#######################################################

#set vars for script, relevant in my local environment
CS2DIR="/home/bhilv/steamservers"
SERVER_SESSION="cs2"
UPDATE_SESSION="cs2update"
START_SCRIPT="$CS2DIR/game/bin/linuxsteamrt64/startcs2server.sh"
STEAMCMD="/usr/games/steamcmd"

LOG_DIR="$HOME/Scripts"
LOG="$LOG_DIR/cs2watchdog.log"
LOCK="/tmp/cs2watchdog.lock"

#######################################################

mkdir -p "$LOG_DIR"

#lock to revent overlapping runs of manual execution or cron exec
exec 9>"$LOCK"
flock -n 9 || exit 0

ts() { date "+%Y-%m-%d %H:%M:%S %Z"; }
log() { echo "[$(ts)] $*" >> "$LOG"; }

screen_has() {
  screen -list 2>/dev/null | grep -qE "[.]${1}[[:space:]]"
}

#add metamod to the top of the search path in gameinfo.gi
fix_gameinfo_metamod() {
 
  local gi="$CS2DIR/game/csgo/gameinfo.gi"

  if [ ! -f "$gi" ]; then
    log "ERROR: gameinfo.gi not found at $gi"
    exit 1
  fi

  log "Ensuring Metamod search path is present and ordered in gameinfo.gi"

  #remove any existing metamod entries if present
  sed -i '/^[[:space:]]*Game[[:space:]]\+csgo\/addons\/metamod[[:space:]]*$/d' "$gi"

  #re-insert Metamod as the first Game search path inside SearchPaths (after Game_LowViolence and prior ot other paths).
  awk '
    BEGIN { in_searchpaths=0; inserted=0; saw_lowviolence=0 }
    {
      line=$0
      if (line ~ /^[[:space:]]*SearchPaths[[:space:]]*$/) { in_searchpaths=1; print line; next }
      if (in_searchpaths==1 && line ~ /^[[:space:]]*\{[[:space:]]*$/) { in_searchpaths=2; print line; next }
      if (in_searchpaths==2) {
        #search for Game_LowViolence, print it and insert metamod right after it.
        if (line ~ /^[[:space:]]*Game_LowViolence[[:space:]]+/) {
          saw_lowviolence=1
          print line
          if (inserted==0) {
            print "\t\t\tGame\tcsgo/addons/metamod"
            inserted=1
          }
          next
        }

        if (inserted==0 && line ~ /^[[:space:]]*(Game|Mod|Platform)[[:space:]]+/) {
          print "\t\t\tGame\tcsgo/addons/metamod"
          inserted=1
          print line
          next
        }

        #if block ends and metamod still havent inserted, insert before closing brace.
        if (line ~ /^[[:space:]]*\}[[:space:]]*$/) {
          if (inserted==0) {
            print "\t\t\tGame\tcsgo/addons/metamod"
            inserted=1
          }
          print line
          in_searchpaths=0
          next
        }
      }

      print line
    }
  ' "$gi" > "$gi.tmp" && mv "$gi.tmp" "$gi"

  log "Metamod search path enforced successfully"
}


log "===== CS2 watchdog run starting ====="

#check for screens, steamcmd session, and server start script at /game/bin/linuxrt.../$START_SCRIPT
command -v screen >/dev/null 2>&1 || { log "ERROR: screen not found"; exit 1; }
[ -x "$STEAMCMD" ] || { log "ERROR: steamcmd not found at $STEAMCMD"; exit 1; }
[ -x "$START_SCRIPT" ] || { log "ERROR: start script missing/not executable: $START_SCRIPT"; exit 1; }

#main Logic
#stop server if running (screen session 'cs2')
if screen_has "$SERVER_SESSION"; then
  log "Server session '$SERVER_SESSION' detected; stopping it."
  screen -S "$SERVER_SESSION" -X quit || true
  sleep 5
else
  log "Server session '$SERVER_SESSION' not running."
fi

#ensure no stale update screen is around
if screen_has "$UPDATE_SESSION"; then
  log "Stale update session '$UPDATE_SESSION' detected; closing it."
  screen -S "$UPDATE_SESSION" -X quit || true
  sleep 2
fi

#start update in screen 'cs2update'
log "Starting update in screen session '$UPDATE_SESSION'."
screen -dmS "$UPDATE_SESSION" bash -lc "
  set -euo pipefail
  echo '[cs2update] $(date) SteamCMD update starting...'
  '$STEAMCMD' +force_install_dir '$CS2DIR' +login anonymous +app_update 730 validate +quit
  echo '[cs2update] $(date) SteamCMD update finished.'
"

#wait for update to finish
log \"Waiting for update session '$UPDATE_SESSION' to finish...\"
while screen_has "$UPDATE_SESSION"; do
  sleep 10
done
log \"Update session finished.\"

#verify cs2 binary exists (to prevent 'screen is terminating' from missing binary issue)
if [ ! -x "$CS2DIR/game/bin/linuxsteamrt64/cs2" ]; then
  log "ERROR: cs2 binary missing after update: $CS2DIR/game/bin/linuxsteamrt64/cs2"
  exit 1
fi


#call fix_gameinfo_metamod to ensure Metamod search path exists after update
fix_gameinfo_metamod

#start/restart server in screen session 'cs2'
if screen_has "$SERVER_SESSION"; then
  log "Server session '$SERVER_SESSION' already exists; not starting another."
  exit 0
fi

log "Starting server in screen session '$SERVER_SESSION'."
screen -dmS "$SERVER_SESSION" bash -lc "'$START_SCRIPT'"

log "CS2 watchdog complete."
