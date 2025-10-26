#!/usr/bin/env zsh

pipx ensurepath &> /dev/null

pipx install yt-dlp &> /dev/null

# YouTube playlist audio daemon with unified command + playback control
ytpl() {
  local sub=$1
  shift

  local pidfile="/tmp/ytpl.pid"
  local logfile="/tmp/ytpl.log"
  local ipc="/tmp/ytpl.sock"

  case "$sub" in
    start)
      local url=$1
      if [[ -z "$url" ]]; then
        echo "Usage: ytpl start <playlist_url>"
        return 1
      fi

      if [[ -f "$pidfile" ]] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
        echo "ytpl is already running (PID $(cat "$pidfile"))"
        return 1
      fi

      [[ -e "$ipc" ]] && rm -f "$ipc"

      # Start mpv in background with IPC server and logging
      (
        mpv --no-video \
            --ytdl=yes \
            --script-opts="ytdl_hook-ytdl_path=$(which yt-dlp)" \
            --ytdl-format="bestaudio/best" \
            --loop-playlist=no \
            --input-ipc-server="$ipc" \
            "$url" >"$logfile" 2>&1 &
        echo $! > "$pidfile"
      )
      echo "ytpl started (PID $(cat "$pidfile"))"
      echo "Logs: $logfile"
      ;;
    stop)
      if [[ -f "$pidfile" ]]; then
        kill "$(cat "$pidfile")" 2>/dev/null && echo "ytpl stopped" || echo "ytpl not running"
        rm -f "$pidfile"
        [[ -e "$ipc" ]] && rm -f "$ipc"
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
        tail -n 30 "$logfile"
      else
        echo "No logs found."
      fi
      ;;
    player)
      if [[ ! -S "$ipc" ]]; then
        echo "ytpl player: IPC socket not found. Is ytpl running?"
        return 1
      fi

      local cmd=$1
      case "$cmd" in
        play|pause)
          echo '{ "command": ["cycle", "pause"] }' | socat - "$ipc"
          ;;
        stop)
          echo '{ "command": ["quit"] }' | socat - "$ipc"
          ;;
        next)
          echo '{ "command": ["playlist-next", "force"] }' | socat - "$ipc"
          ;;
        prev)
          echo '{ "command": ["playlist-prev", "force"] }' | socat - "$ipc"
          ;;
        volume-up)
          echo '{ "command": ["add", "volume", 5] }' | socat - "$ipc"
          ;;
        volume-down)
          echo '{ "command": ["add", "volume", -5] }' | socat - "$ipc"
          ;;
        seek-forward)
          echo '{ "command": ["seek", 10, "relative"] }' | socat - "$ipc"
          ;;
        seek-backward)
          echo '{ "command": ["seek", -10, "relative"] }' | socat - "$ipc"
          ;;
        *)
          echo "Usage: ytpl player {play|pause|stop|next|prev|volume-up|volume-down|seek-forward|seek-backward}"
          ;;
      esac
      ;;
    *)
      echo "Usage:"
      echo "  ytpl start <playlist_url>"
      echo "  ytpl stop"
      echo "  ytpl status"
      echo "  ytpl logs"
      echo "  ytpl player {play|pause|stop|next|prev|volume-up|volume-down|seek-forward|seek-backward}"
      ;;
  esac
}
