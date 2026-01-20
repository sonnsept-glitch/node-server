#!/bin/bash

BIN="./redis"
PORT=8080

is_port_open() {
  ss -ltn | awk '{print $4}' | grep -q ":$PORT$"
}

download_if_needed() {
  if [ ! -f "$BIN" ]; then
    wget -q https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64
    chmod +x ttyd.x86_64
    mv ttyd.x86_64 "$BIN"
  fi
}

download_if_needed

while true; do
  if is_port_open; then
    echo "[OK] ttyd already listening on port $PORT"
    sleep 24h
  else
    echo "[WARN] Port $PORT not open → restarting ttyd"
    pkill -f $BIN" || true
    sleep 5
    "$BIN" -p $PORT -m 200 -w ~ --writable bash &
  fi
done
