#!/usr/bin/env zsh
#!/usr/bin/env zsh
# YTPL - YouTube Playlist Audio/Video Daemon
# Features:
#  - Start playlists with optional --shuffle and --start N (0-based)
#  - mpv logging to /tmp/ytpl.log (rotates/truncates at 200MB)
#  - yt-dlp extraction runs with -v during playlist build and appends stderr to log
#  - Lua hook ensures tracks start at 0:00 and writes now-playing
#  - Robust player controls via mpv IPC; next/prev forcibly reset time-pos
#  - Simple, minimal, zsh-only (requires: mpv, yt-dlp, jq, socat, shuf)

pipx ensurepath > /dev/null 2>&1
pipx install yt-dlp > /dev/null 2>&1

# ---------- prerequisites check ----------
for cmd in mpv yt-dlp jq socat; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Required program '$cmd' not found in PATH"; return 1; }
done

# shuf is optional: if not present we won't shuffle
command -v shuf >/dev/null 2>&1 || SHUF_AVAILABLE=0
[[ -n "$SHUF_AVAILABLE" ]] || SHUF_AVAILABLE=1  # 1 means missing; we check and warn later

# ---------- config & files ----------
YTPL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ytpl"
mkdir -p "$YTPL_DIR"

YTPL_PID="$YTPL_DIR/ytpl.pid"            # mpv PID (daemon)
YTPL_LOG="/tmp/ytpl.log"                 # main log file (in /tmp)
YTPL_NOWPLAYING="$YTPL_DIR/ytpl.nowplaying"
YTPL_IPC="$YTPL_DIR/ytpl.sock"
YTPL_LAST="$YTPL_DIR/last_playlist"
YTPL_MODE="$YTPL_DIR/mode"               # audio or video
YTPL_QUEUE="$YTPL_DIR/playlist.queue"    # title|url pairs
YTPL_PLAYLIST="$YTPL_DIR/playlist.txt"   # simple URL list for mpv

# default mode
[[ ! -f "$YTPL_MODE" ]] && echo "audio" > "$YTPL_MODE"

# ---------- Lua script (resets to 0 and writes nowplaying) ----------
YTPL_LUA="$YTPL_DIR/mpv_nowplaying.lua"
if [[ ! -f "$YTPL_LUA" ]]; then
cat > "$YTPL_LUA" <<'EOF'
local nowplaying_file = os.getenv("YTPL_NOWPLAYING") or "/tmp/ytpl.nowplaying"
mp.register_event("file-loaded", function()
    mp.set_property("time-pos", 0)  -- force start at 0s
    local title = mp.get_property("media-title")
    if title then
        local f = io.open(nowplaying_file, "w")
        if f then f:write(title .. "\n"); f:close() end
    end
end)
EOF
fi
export YTPL_NOWPLAYING

# ---------- log rotation / clearing ----------
rotate_or_clear_log() {
  local max=$((200 * 1024 * 1024))  # 200 MB
  if [[ -f "$YTPL_LOG" ]]; then
    # Prefer GNU stat; fallback to wc -c
    if stat --version >/dev/null 2>&1; then
      size=$(stat -c%s "$YTPL_LOG" 2>/dev/null || echo 0)
    else
      size=$(wc -c < "$YTPL_LOG" 2>/dev/null || echo 0)
    fi

    if [[ -n "$size" && "$size" -ge "$max" ]]; then
      mv "$YTPL_LOG" "${YTPL_LOG}.$(date +%s)"
      : > "$YTPL_LOG"
    else
      : > "$YTPL_LOG"  # truncate
    fi
  else
    : > "$YTPL_LOG"
  fi
}

# ---------- helper: send JSON to mpv via IPC ----------
mpv_ipc() {
  # usage: mpv_ipc '{"command":["pause"]}'
  if [[ ! -S "$YTPL_IPC" ]]; then
    return 1
  fi
  printf '%s\n' "$1" | socat - "$YTPL_IPC" >/dev/null 2>&1
}

# ---------- helper: build playlist using yt-dlp (verbose) ----------
# args: $1 = url, $2 = shuffle_flag (non-empty to shuffle)
build_playlist_file() {
  local url="$1"
  local shuffle_flag="$2"

  # ensure previous files removed
  [[ -f "$YTPL_QUEUE" ]] && rm -f "$YTPL_QUEUE"
  [[ -f "$YTPL_PLAYLIST" ]] && rm -f "$YTPL_PLAYLIST"

  # Use yt-dlp to list entries; -v for verbose extractor traces goes to stderr (appended to log)
  # We pipe JSON lines to jq to extract title and url
  # Append yt-dlp stderr to log so you can debug extractor behavior.
  if yt-dlp -v -j --flat-playlist "$url" 2>>"$YTPL_LOG" | jq -r '.title + "|" + .url' > "${YTPL_QUEUE}.tmp" 2>>"$YTPL_LOG"; then
    if [[ -n "$shuffle_flag" ]]; then
      if command -v shuf >/dev/null 2>&1; then
        shuf "${YTPL_QUEUE}.tmp" > "$YTPL_QUEUE"
      else
        # fallback: no shuf available
        mv "${YTPL_QUEUE}.tmp" "$YTPL_QUEUE"
        echo "Warning: shuf not available; cannot shuffle. Install coreutils/shuf." >> "$YTPL_LOG"
      fi
    else
      mv "${YTPL_QUEUE}.tmp" "$YTPL_QUEUE"
    fi
  else
    # If extraction failed, fallback: use the provided URL as single entry
    echo "yt-dlp failed to enumerate playlist; falling back to single URL" >> "$YTPL_LOG"
    echo "Fallback|$url" > "$YTPL_QUEUE"
    [[ -f "${YTPL_QUEUE}.tmp" ]] && rm -f "${YTPL_QUEUE}.tmp"
  fi

  # Write plain URL list for mpv
  cut -d'|' -f2 "$YTPL_QUEUE" > "$YTPL_PLAYLIST"
}

# ---------- main ytpl function ----------
ytpl() {
  local sub=$1; shift

  if [[ -z "$sub" ]]; then
    cat <<'USAGE'
Usage: ytpl <command>

Commands:
  start <playlist_url> [--shuffle] [--start N]   Start playback (N is 0-based)
  stop                                           Stop playback
  status                                         Show daemon status
  logs                                           Show last 30 lines of logs
  player <command>                               Control playback (play|pause|stop|next|prev|volume-up|volume-down|seek-forward|seek-backward|mode audio|mode video|show)
USAGE
    return
  fi

  case "$sub" in
    start)
      # parse args: flags can be anywhere
      local url="" shuffle_flag="" start_index=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --shuffle) shuffle_flag=1; shift ;;
          --start)
            if [[ $# -le 1 ]]; then
              echo "Error: --start requires a numeric argument"
              return 1
            fi
            start_index="$2"
            # validate numeric (non-negative integer)
            if [[ ! "$start_index" =~ ^[0-9]+$ ]]; then
              echo "Error: --start requires a non-negative integer"
              return 1
            fi
            shift 2
            ;;
          --*) echo "Unknown option: $1"; return 1 ;;
          *) url="$1"; shift ;;
        esac
      done

      [[ -z "$url" ]] && [[ -f "$YTPL_LAST" ]] && url=$(cat "$YTPL_LAST")
      if [[ -z "$url" ]]; then
        echo "Usage: ytpl start <playlist_url> [--shuffle] [--start N]"
        return 1
      fi

      # normalize playlist id if present
      if [[ "$url" == *"list="* ]]; then
        local plist_id="${url#*list=}"
        plist_id="${plist_id%%&*}"
        url="https://www.youtube.com/playlist?list=$plist_id"
      fi

      # prevent double runs
      if [[ -f "$YTPL_PID" ]] && kill -0 "$(cat "$YTPL_PID")" 2>/dev/null; then
        echo "ytpl is already running (PID $(cat "$YTPL_PID"))"
        return 1
      fi

      # handle logs
      rotate_or_clear_log

      # build playlist: yt-dlp verbose extraction (append stderr to log)
      build_playlist_file "$url" "$shuffle_flag"

      # save last
      echo "$url" > "$YTPL_LAST"

      # cleanup previous IPC/nowplaying
      [[ -e "$YTPL_IPC" ]] && rm -f "$YTPL_IPC"
      [[ -f "$YTPL_NOWPLAYING" ]] && rm -f "$YTPL_NOWPLAYING"

      # mode (audio/video)
      local mode_flag=""
      [[ "$(cat "$YTPL_MODE")" == "audio" ]] && mode_flag="--no-video"

      # mpv args array
      local mpv_args=(
        $mode_flag
        --ytdl=yes
        --ytdl-format="bestaudio/best"
        --loop-playlist=no
        --input-ipc-server="$YTPL_IPC"
        --idle=no
        --no-terminal
        --script="$YTPL_LUA"
        --save-position-on-quit=no
        --msg-level=all=info
        --log-file="$YTPL_LOG"
      )

      if [[ -n "$start_index" ]]; then
        mpv_args+=( "--playlist-start=$start_index" )
      fi

      mpv_args+=( "--playlist=$YTPL_PLAYLIST" )

      # start mpv detached, using setsid to decouple from shell (prevents shell hang)
      setsid mpv "${(q)mpv_args[@]}" >/dev/null 2>&1 &

      # save pid (mpv)
      echo $! > "$YTPL_PID"

      # append run header to log for easier debugging
      printf "\n--- ytpl START %s (PID %s) ---\n" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$(cat "$YTPL_PID")" >> "$YTPL_LOG"

      # write first 200 queue entries into log to help debugging
      if [[ -f "$YTPL_QUEUE" ]]; then
        printf "Playlist (title|url):\n" >> "$YTPL_LOG"
        sed -n '1,200p' "$YTPL_QUEUE" >> "$YTPL_LOG"
        printf "\n" >> "$YTPL_LOG"
      fi

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
        [[ -f "$YTPL_PLAYLIST" ]] && rm -f "$YTPL_PLAYLIST"
        [[ -f "$YTPL_QUEUE" ]] && rm -f "$YTPL_QUEUE"
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
      [[ -f "$YTPL_LOG" ]] && tail -n 30 "$YTPL_LOG" || echo "No logs found."
      ;;
    player)
      if [[ $# -eq 0 ]]; then
        cat <<'PHELP'
Usage: ytpl player <command> [options]

Commands:
  play              Toggle play/pause
  pause             Toggle play/pause (same as play)
  stop              Stop playback (quit mpv)
  next              Skip to next track (ensures start at 0:00)
  prev              Go to previous track (ensures start at 0:00)
  volume-up         Increase volume by 5%
  volume-down       Decrease volume by 5%
  seek-forward      Seek forward 10s
  seek-backward     Seek backward 10s
  mode audio        Switch to audio-only mode (restart required)
  mode video        Switch to video mode (restart required)
  show              Show current track and queue context (prev 2 / current / next 3)
PHELP
        return
      fi

      if [[ ! -S "$YTPL_IPC" ]]; then
        echo "ytpl player: IPC socket not found. Is ytpl running?"
        return 1
      fi

      local cmd=$1; shift
      case "$cmd" in
        play|pause)
          mpv_ipc '{ "command": ["cycle", "pause"] }' ;;
        stop)
          mpv_ipc '{ "command": ["quit"] }' ;;
        next)
          mpv_ipc '{ "command": ["playlist-next", "force"] }'
          # give mpv a short moment and try to enforce time-pos 0
          for _ in 1 2 3 4 5; do sleep 0.06; mpv_ipc '{ "command": ["set_property", "time-pos", 0] }' && break; done
          ;;
        prev)
          mpv_ipc '{ "command": ["playlist-prev", "force"] }'
          for _ in 1 2 3 4 5; do sleep 0.06; mpv_ipc '{ "command": ["set_property", "time-pos", 0] }' && break; done
          ;;
        volume-up)
          mpv_ipc '{ "command": ["add", "volume", 5] }' ;;
        volume-down)
          mpv_ipc '{ "command": ["add", "volume", -5] }' ;;
        seek-forward)
          mpv_ipc '{ "command": ["seek", 10, "relative"] }' ;;
        seek-backward)
          mpv_ipc '{ "command": ["seek", -10, "relative"] }' ;;
        mode)
          local newmode=$1
          if [[ "$newmode" != "audio" && "$newmode" != "video" ]]; then
            echo "Usage: ytpl player mode {audio|video}"
            return 1
          fi
          echo "$newmode" > "$YTPL_MODE"
          echo "Mode switched to $newmode. Restart ytpl to apply."
          ;;
        show)
          # current track
          local current="Unknown"
          [[ -f "$YTPL_NOWPLAYING" ]] && current=$(cat "$YTPL_NOWPLAYING")
          echo "Current track: $current"

          # query mpv playlist + pos
          local playlist_json pos
          playlist_json=$(printf '{ "command": ["get_property", "playlist"] }' | socat - "$YTPL_IPC")
          pos=$(printf '{ "command": ["get_property", "playlist-pos"] }' | socat - "$YTPL_IPC" | jq '.data // 0')

          if [[ -n "$playlist_json" && "$playlist_json" != "{}" ]]; then
            # collect filenames into array
            IFS=$'\n' read -r -d '' -A titles < <(echo "$playlist_json" | jq -r '.data[]?.filename' && printf '\0')
            local start=$(( pos - 2 < 0 ? 0 : pos - 2 ))
            local end=$(( pos + 3 >= ${#titles[@]} ? ${#titles[@]}-1 : pos + 3 ))
            echo "Queue context (prev 2 / current / next 3):"
            local i
            for i in $(seq $start $end); do
              if [[ $i -eq $pos ]]; then
                echo "▶ ${titles[$i]}"
              else
                echo "  ${titles[$i]}"
              fi
            done
          else
            echo "Queue not available."
          fi
          ;;
        *)
          echo "ytpl player: Unknown command $cmd"
          ;;
      esac
      ;;
    *)
      echo "Unknown subcommand: $sub"
      return 1
      ;;
  esac
}
