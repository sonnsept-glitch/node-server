#!/bin/bash

BIN="./redis"          # ttyd binary
PORT=8080
URL="http://127.0.0.1:${PORT}"
CHECK_INTERVAL=600     # 10 phút

check_http() {
  curl -I --max-time 2 -s "$URL" | head -n 1 | grep -q "200"
}

is_running() {
  pgrep -f "$BIN" > /dev/null 2>&1
}

download_if_needed() {
  if [ ! -f "$BIN" ]; then
    echo "[INFO] Downloading ttyd..."
    wget -q https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64
    chmod +x ttyd.x86_64
    mv ttyd.x86_64 "$BIN"
  fi
}

start_ttyd() {
  echo "[START] ttyd starting on port $PORT"
  "$BIN" -p "$PORT" -m 200 -w ~ --writable bash &
}

kill_ttyd() {
  echo "[KILL] ttyd stopped"
  pkill -f "$BIN" || true
}

### INIT STEP ###
download_if_needed

if check_http; then
  echo "[INIT] ttyd already running & healthy"
else
  echo "[INIT] ttyd not running or unhealthy → start"
  kill_ttyd
  sleep 2
  start_ttyd
fi

### HEALTH CHECK LOOP ###
while true; do
  sleep "$CHECK_INTERVAL"

  if check_http; then
    echo "[OK] ttyd healthy ($(date))"
  else
    echo "[FAIL] ttyd unhealthy → restart ($(date))"
    kill_ttyd
    sleep 3
    start_ttyd
  fi
done
