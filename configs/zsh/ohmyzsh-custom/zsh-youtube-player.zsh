#!/usr/bin/env zsh

pipx ensurepath &> /dev/null

pipx install yt-dlp &> /dev/null

# YouTube playlist player (mpv + yt-dlp backend, background, logs)
ytpl() {
  local action=$1
  local url=$2
  local pidfile="/tmp/ytpl.pid"
  local logfile="/tmp/ytpl.log"

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

      # Use system yt-dlp as mpv’s backend
      ( mpv \
          --no-video \
          --ytdl=yes \
          --script-opts="ytdl_hook-ytdl_path=$(which yt-dlp)" \
          --ytdl-format="bestaudio/best" \
          --loop-playlist=no \
          --msg-level=ffmpeg=warn \
          "$url" >"$logfile" 2>&1 & echo $! >"$pidfile" )

      echo "ytpl started (PID $(cat "$pidfile"))"
      echo "Logs: $logfile"
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
    logs)
      if [[ -f "$logfile" ]]; then
        echo "--- ytpl logs ---"
        tail -n 30 "$logfile"
      else
        echo "No logs found."
      fi
      ;;
    *)
      echo "Usage: ytpl {start|stop|status|logs} [playlist_url]"
      ;;
  esac
}
