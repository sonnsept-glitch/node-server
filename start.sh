#!/bin/bash

BIN="./redis"          # ttyd binary
PID_FILE="/tmp/redis_ttyd.pid"
PORT=8080
URL="http://127.0.0.1:${PORT}"
CHECK_INTERVAL=120

check_http() {
  curl -fs --max-time 2 "$URL" >/dev/null
}

download_if_needed() {
  if [ ! -f "$BIN" ]; then
    wget -q https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64
    chmod +x ttyd.x86_64
    mv ttyd.x86_64 "$BIN"
  fi
}

start_ttyd() {
  "$BIN" -p "$PORT" -m 200 -w ~ --writable bash &
  echo $! > "$PID_FILE"
}

kill_ttyd() {
  if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    kill -9 "$PID" 2>/dev/null || true
    rm -f "$PID_FILE"
  fi

  pkill -9 -f "^\./redis" 2>/dev/null || true
  lsof -ti:$PORT | xargs -r kill -9 2>/dev/null || true
}

download_if_needed

if ! check_http; then
  kill_ttyd
  start_ttyd
fi

while true; do
  sleep "$CHECK_INTERVAL"

  if ! check_http; then
    kill_ttyd
    sleep 1
    start_ttyd
  fi
done
