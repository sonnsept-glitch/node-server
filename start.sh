#!/bin/bash
BIN="./redis"
PORT=8080
URL="http://127.0.0.1:${PORT}"
CHECK_INTERVAL=600
LOCKFILE="/tmp/ttyd_monitor.lock"

check_http() {
  curl -I --max-time 2 -s "$URL" | head -n 1 | grep -q "200"
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
  echo "[KILL] Stopping ttyd..."
  # Chỉ kill ttyd binary, KHÔNG dùng pkill với pattern chung
  killall -9 "$BIN" 2>/dev/null || true
  sleep 2
}

cleanup_old_monitors() {
  # Lấy PID hiện tại
  current_pid=$$
  
  # Đọc PID từ lock file cũ
  if [ -f "$LOCKFILE" ]; then
    old_pid=$(cat "$LOCKFILE")
    # Chỉ kill nếu PID cũ khác PID hiện tại VÀ process đó còn tồn tại
    if [ "$old_pid" != "$current_pid" ] && [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
      echo "[CLEANUP] Killing old monitor script (PID: $old_pid)..."
      kill -9 "$old_pid" 2>/dev/null || true
      sleep 1
    fi
  fi
}

### INIT STEP ###
download_if_needed

# Cleanup script cũ trước
cleanup_old_monitors

# Ghi PID hiện tại vào lock file
echo $$ > "$LOCKFILE"

# Cleanup khi script exit
trap "rm -f $LOCKFILE" EXIT INT TERM

if check_http; then
  echo "[INIT] ttyd already running & healthy ($(date))"
else
  echo "[INIT] ttyd not running or unhealthy → start"
  kill_ttyd
  sleep 5
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
