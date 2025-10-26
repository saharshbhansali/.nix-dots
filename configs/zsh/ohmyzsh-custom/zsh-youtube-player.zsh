#!/usr/bin/env zsh

pipx ensurepath &> /dev/null

pipx install yt-dlp &> /dev/null

# YouTube playlist audio daemon with unified command + playback control, live Now Playing & A/V mode
YTPL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ytpl"
mkdir -p "$YTPL_DIR"

# Files
YTPL_PID="/tmp/ytpl.pid"
YTPL_LOG="/tmp/ytpl.log"
YTPL_NOWPLAYING="/tmp/ytpl.nowplaying"
YTPL_IPC="/tmp/ytpl.sock"
YTPL_LAST="$YTPL_DIR/last_playlist"
YTPL_MODE="$YTPL_DIR/mode"  # audio or video

# Default mode
[[ ! -f "$YTPL_MODE" ]] && echo "audio" > "$YTPL_MODE"

ytpl() {
  local sub=$1
  shift

  case "$sub" in
    start)
      local url=$1
      [[ -z "$url" ]] && [[ -f "$YTPL_LAST" ]] && url=$(cat "$YTPL_LAST")
      if [[ -z "$url" ]]; then
        echo "Usage: ytpl start <playlist_url>"
        return 1
      fi

      if [[ -f "$YTPL_PID" ]] && kill -0 "$(cat "$YTPL_PID")" 2>/dev/null; then
        echo "ytpl is already running (PID $(cat "$YTPL_PID"))"
        return 1
      fi

      # Save last playlist
      echo "$url" > "$YTPL_LAST"

      # Remove old IPC & Now Playing
      [[ -e "$YTPL_IPC" ]] && rm -f "$YTPL_IPC"
      [[ -f "$YTPL_NOWPLAYING" ]] && rm -f "$YTPL_NOWPLAYING"

      # Determine mode
      local mode_flag
      if [[ "$(cat "$YTPL_MODE")" == "audio" ]]; then
        mode_flag="--no-video"
      else
        mode_flag=""
      fi

      # Start mpv in background with IPC, Now Playing logging
      (
        mpv $mode_flag \
            --ytdl=yes \
            --script-opts="ytdl_hook-ytdl_path=$(which yt-dlp)" \
            --ytdl-format="bestaudio/best" \
            --loop-playlist=no \
            --input-ipc-server="$YTPL_IPC" \
            --idle=no \
            --no-terminal \
            --script-opts="osc=no" \
            --msg-level=all=v \
            --term-status-msg="" \
            --input-conf=/dev/null \
            "$url" \
            --really-quiet \
            --script-opts=ytdl_hook=ytdl_path="$(which yt-dlp)" \
            --script-opts="ytdl_hook-write-nowplaying=$YTPL_NOWPLAYING" \
            >"$YTPL_LOG" 2>&1 &
        echo $! > "$YTPL_PID"
      )

      echo "ytpl started in $(cat "$YTPL_MODE") mode (PID $(cat "$YTPL_PID"))"
      echo "Logs: $YTPL_LOG"
      echo "Now Playing: $YTPL_NOWPLAYING"
      ;;
    stop)
      if [[ -f "$YTPL_PID" ]]; then
        kill "$(cat "$YTPL_PID")" 2>/dev/null && echo "ytpl stopped" || echo "ytpl not running"
        rm -f "$YTPL_PID"
        [[ -e "$YTPL_IPC" ]] && rm -f "$YTPL_IPC"
        [[ -f "$YTPL_NOWPLAYING" ]] && rm -f "$YTPL_NOWPLAYING"
      else
        echo "ytpl is not running"
      fi
      ;;
    status)
      if [[ -f "$YTPL_PID" ]] && kill -0 "$(cat "$YTPL_PID")" 2>/dev/null; then
        echo "ytpl is running (PID $(cat "$YTPL_PID")) in $(cat "$YTPL_MODE") mode"
      else
        echo "ytpl is not running"
      fi
      ;;
    logs)
      if [[ -f "$YTPL_LOG" ]]; then
        tail -n 30 "$YTPL_LOG"
      else
        echo "No logs found."
      fi
      ;;
    player)
      if [[ ! -S "$YTPL_IPC" ]]; then
        echo "ytpl player: IPC socket not found. Is ytpl running?"
        return 1
      fi
      local cmd=$1
      case "$cmd" in
        play|pause)
          echo '{ "command": ["cycle", "pause"] }' | socat - "$YTPL_IPC"
          ;;
        stop)
          echo '{ "command": ["quit"] }' | socat - "$YTPL_IPC"
          ;;
        next)
          echo '{ "command": ["playlist-next", "force"] }' | socat - "$YTPL_IPC"
          ;;
        prev)
          echo '{ "command": ["playlist-prev", "force"] }' | socat - "$YTPL_IPC"
          ;;
        volume-up)
          echo '{ "command": ["add", "volume", 5] }' | socat - "$YTPL_IPC"
          ;;
        volume-down)
          echo '{ "command": ["add", "volume", -5] }' | socat - "$YTPL_IPC"
          ;;
        seek-forward)
          echo '{ "command": ["seek", 10, "relative"] }' | socat - "$YTPL_IPC"
          ;;
        seek-backward)
          echo '{ "command": ["seek", -10, "relative"] }' | socat - "$YTPL_IPC"
          ;;
        mode)
          local newmode=$2
          if [[ "$newmode" != "audio" && "$newmode" != "video" ]]; then
            echo "Usage: ytpl player mode {audio|video}"
            return 1
          fi
          echo "$newmode" > "$YTPL_MODE"
          echo "Mode switched to $newmode. Restart ytpl to apply."
          ;;
        show)
          if [[ -f "$YTPL_NOWPLAYING" ]]; then
            cat "$YTPL_NOWPLAYING"
          else
            echo "Nothing playing right now."
          fi
          ;;
        *)
          echo "Usage: ytpl player {play|pause|stop|next|prev|volume-up|volume-down|seek-forward|seek-backward|mode audio|mode video|show}"
          ;;
      esac
      ;;
    *)
      echo "Usage:"
      echo "  ytpl start <playlist_url>"
      echo "  ytpl stop"
      echo "  ytpl status"
      echo "  ytpl logs"
      echo "  ytpl player {play|pause|stop|next|prev|volume-up|volume-down|seek-forward|seek-backward|mode audio|mode video|show}"
      ;;
  esac
}
