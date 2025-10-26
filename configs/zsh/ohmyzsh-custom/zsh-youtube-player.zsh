#!/usr/bin/env zsh

pipx ensurepath &> /dev/null

pipx install yt-dlp &> /dev/null

# YouTube playlist player (background, silent)
ytpl() {
  local action=$1
  local url=$2
  local pidfile="/tmp/ytpl.pid"

  case "$action" in
    start)
      if [[ -z "$url" ]]; then
        echo "Usage: ytpl start <playlist_url>"
        return 1
      fi
      if [[ -f "$pidfile" ]] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
        echo "ytpl is already running (PID $(cat "$pidfile"))"
        return 1
      fi
      ( yt-dlp -o - "$url" 2>/dev/null | mpv --no-video -  >/dev/null 2>&1 & echo $! > "$pidfile" )
      echo "ytpl started (PID $(cat "$pidfile"))"
      ;;
    stop)
      if [[ -f "$pidfile" ]]; then
        kill "$(cat "$pidfile")" 2>/dev/null && echo "ytpl stopped" || echo "ytpl not running"
        rm -f "$pidfile"
      else
        echo "ytpl is not running"
      fi
      ;;
    status)
      if [[ -f "$pidfile" ]] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
        echo "ytpl is running (PID $(cat "$pidfile"))"
      else
        echo "ytpl is not running"
      fi
      ;;
    *)
      echo "Usage: ytpl {start|stop|status} [playlist_url]"
      ;;
  esac
}
