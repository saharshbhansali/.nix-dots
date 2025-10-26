#!/usr/bin/env zsh
# ytpl - YouTube Playlist Audio/Video Daemon (updated drop-in)
# Supports: lockdir, stale timeout (30m), --force, doctor, cookies auto-detect,
# mpv IPC player controls, verbose yt-dlp extraction, log rotation, traps for cleanup.

YTPL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ytpl"
YTPL_LOCKDIR="/tmp/ytpl-lock.$USER"
YTPL_PID="$YTPL_DIR/ytpl.pid"
YTPL_LOG="/tmp/ytpl.log"
YTPL_NOWPLAYING="$YTPL_DIR/ytpl.nowplaying"
YTPL_IPC="$YTPL_DIR/ytpl.sock"
YTPL_LAST="$YTPL_DIR/last_playlist"
YTPL_MODE="$YTPL_DIR/mode"
YTPL_QUEUE="$YTPL_DIR/playlist.queue"
YTPL_PLAYLIST="$YTPL_DIR/playlist.txt"
YTPL_LUA="$YTPL_DIR/mpv_nowplaying.lua"
YTDLP_COOKIES_PATH="${YTDLP_COOKIES_PATH:-$HOME/.config/yt-dlp/cookies.txt}"

LOCK_STALE_SECS=$((30*60))  # 30 minutes

mkdir -p "$YTPL_DIR"
export YTPL_NOWPLAYING

# ------------------------- Lua helper -------------------------
ensure_lua() {
  [[ -f "$YTPL_LUA" ]] && return 0
  cat > "$YTPL_LUA" <<'EOF'
local nowplaying_file = os.getenv("YTPL_NOWPLAYING") or "/tmp/ytpl.nowplaying"
mp.register_event("file-loaded", function()
    mp.set_property("time-pos", 0)
    local title = mp.get_property("media-title")
    if title then
        local f = io.open(nowplaying_file, "w")
        if f then f:write(title .. "\n"); f:close() end
    end
end)
EOF
}

# ------------------------- Logging -------------------------
rotate_or_clear_log() {
  local max=$((200 * 1024 * 1024))
  if [[ -f "$YTPL_LOG" ]]; then
    local size=0
    if stat --version >/dev/null 2>&1; then
      size=$(stat -c%s "$YTPL_LOG" 2>/dev/null || echo 0)
    else
      size=$(wc -c < "$YTPL_LOG" 2>/dev/null || echo 0)
    fi
    if [[ "$size" -ge "$max" ]]; then
      mv "$YTPL_LOG" "${YTPL_LOG}.$(date +%s)"
      : > "$YTPL_LOG"
    else
      : > "$YTPL_LOG"
    fi
  else
    : > "$YTPL_LOG"
  fi
}

# ------------------------- Lockdir helpers -------------------------
_lock_ts() { cat "$YTPL_LOCKDIR/owner_ts" 2>/dev/null || echo 0 }
_lock_owner() { cat "$YTPL_LOCKDIR/owner_pid" 2>/dev/null || echo "" }
_lock_mpvpid() { cat "$YTPL_LOCKDIR/mpv_pid" 2>/dev/null || echo "" }

_acquire_lock_force_if_stale() {
  if mkdir "$YTPL_LOCKDIR" 2>/dev/null; then
    echo "$$" > "$YTPL_LOCKDIR/owner_pid"
    date +%s > "$YTPL_LOCKDIR/owner_ts"
    return 0
  fi

  local ownerpid owner_ts now age
  ownerpid=$(_lock_owner)
  owner_ts=$(_lock_ts)
  owner_ts=${owner_ts:-0}       # <-- fix here
  now=$(date +%s)
  age=$(( now - owner_ts ))     # <-- works in zsh now

  if [[ $age -ge $LOCK_STALE_SECS ]]; then
    echo "ytpl: found stale lock (age ${age}s) — clearing" >> "$YTPL_LOG"
    rm -rf "$YTPL_LOCKDIR"
    if mkdir "$YTPL_LOCKDIR" 2>/dev/null; then
      echo "$$" > "$YTPL_LOCKDIR/owner_pid"
      date +%s > "$YTPL_LOCKDIR/owner_ts"
      return 0
    fi
  fi

  if [[ -n "$ownerpid" ]]; then
    if kill -0 "$ownerpid" 2>/dev/null; then
      return 1
    fi
  fi

  rm -rf "$YTPL_LOCKDIR"
  if mkdir "$YTPL_LOCKDIR" 2>/dev/null; then
    echo "$$" > "$YTPL_LOCKDIR/owner_pid"
    date +%s > "$YTPL_LOCKDIR/owner_ts"
    return 0
  fi
  return 2
}

acquire_lock() { _acquire_lock_force_if_stale }

release_lock() {
  [[ ! -d "$YTPL_LOCKDIR" ]] && return 0
  local ownerpid mpvpid remove=0
  ownerpid=$(_lock_owner)
  mpvpid=$(_lock_mpvpid)

  if [[ "$ownerpid" == "$$" || -z "$ownerpid" ]]; then
    remove=1
  elif ! kill -0 "$ownerpid" 2>/dev/null; then
    remove=1
  elif [[ -n "$mpvpid" ]]; then
    if ! kill -0 "$mpvpid" 2>/dev/null; then
      remove=1
    fi
  fi

  [[ $remove -eq 1 ]] && rm -rf "$YTPL_LOCKDIR"
}

force_clear_lock_and_kill() {
  echo "ytpl: force clearing lock and killing recorded processes..." >> "$YTPL_LOG"
  if [[ -d "$YTPL_LOCKDIR" ]]; then
    local mpvpid ownerpid
    mpvpid=$(_lock_mpvpid)
    ownerpid=$(_lock_owner)
    [[ -n "$mpvpid" ]] && kill "$mpvpid" 2>/dev/null
    sleep 0.15
    [[ -n "$mpvpid" ]] && kill -9 "$mpvpid" 2>/dev/null
    [[ -n "$ownerpid" ]] && kill "$ownerpid" 2>/dev/null
    rm -rf "$YTPL_LOCKDIR"
  fi
  [[ -f "$YTPL_PID" ]] && local pid=$(cat "$YTPL_PID" 2>/dev/null) && [[ -n "$pid" ]] && kill "$pid" 2>/dev/null; sleep 0.15
  [[ -f "$YTPL_PID" ]] && rm -f "$YTPL_PID"
}

trap _on_exit EXIT INT TERM
_on_exit() { release_lock }

# ------------------------- mpv IPC helpers -------------------------
mpv_ipc() {
  [[ ! -S "$YTPL_IPC" ]] && return 2
  printf '%s\n' "$1" | socat - "$YTPL_IPC" 2>/dev/null
  return $?
}

mpv_get_prop() {
  local prop="$1"
  [[ ! -S "$YTPL_IPC" ]] && echo "" && return 1
  printf '{ "command": ["get_property", "%s"] }' "$prop" | socat - "$YTPL_IPC" 2>/dev/null | jq -r '.data // empty' 2>/dev/null
}

# ------------------------- cookie extraction & playlist build -------------------------
build_playlist_file() {
  local url="$1"
  local shuffle_flag="$2"
  local ytdlp_verbose="$3"
  local cookie_override="$4"

  # Clear previous files
  [[ -f "$YTPL_QUEUE" ]] && rm -f "$YTPL_QUEUE"
  [[ -f "$YTPL_PLAYLIST" ]] && rm -f "$YTPL_PLAYLIST"

  local tmp_queue="${YTPL_QUEUE}.tmp"

  # Helper to run yt-dlp and extract playlist entries
  _ytpl_extract() {
    local cookies_arg=("$@")
    yt-dlp "${ytdlp_verbose}" "${cookies_arg[@]}" -j --flat-playlist "$url" 2>>"$YTPL_LOG" \
      | jq -r '.title + "|" + .url' > "$tmp_queue"
  }

  # 1. Try forced browser cookie override
  if [[ -n "$cookie_override" ]]; then
    echo "Attempting cookie extraction from browser (forced): $cookie_override" >> "$YTPL_LOG"
    if _ytpl_extract "--cookies-from-browser" "$cookie_override"; then
      echo "yt-dlp: succeeded with forced browser '$cookie_override'" >> "$YTPL_LOG"
    else
      echo "Forced browser cookie extraction failed for '$cookie_override'" >> "$YTPL_LOG"
      [[ -f "$tmp_queue" ]] && rm -f "$tmp_queue"
    fi
  fi

  # 2. Try explicit cookies file
  if [[ -f "$YTDLP_COOKIES_PATH" ]] && [[ ! -f "$tmp_queue" ]]; then
    echo "Using explicit cookie file: $YTDLP_COOKIES_PATH" >> "$YTPL_LOG"
    if _ytpl_extract "--cookies" "$YTDLP_COOKIES_PATH"; then
      echo "yt-dlp: succeeded with explicit cookie file" >> "$YTPL_LOG"
    else
      echo "yt-dlp with explicit cookies failed; will try browser extraction" >> "$YTPL_LOG"
      [[ -f "$tmp_queue" ]] && rm -f "$tmp_queue"
    fi
  fi

  # 3. Try browsers auto-detection if nothing worked
  if [[ ! -f "$tmp_queue" ]]; then
    local -a browsers=(firefox chromium vivaldi zen brave chrome edge opera whale)
    for b in "${browsers[@]}"; do
      echo "Trying cookies from browser: $b" >> "$YTPL_LOG"
      if _ytpl_extract "--cookies-from-browser" "$b"; then
        echo "yt-dlp: succeeded with browser '$b' cookies" >> "$YTPL_LOG"
        break
      else
        echo "yt-dlp: browser '$b' failed; trying next candidate" >> "$YTPL_LOG"
        [[ -f "$tmp_queue" ]] && rm -f "$tmp_queue"
      fi
    done
  fi

  # 4. Check if extraction succeeded
  if [[ ! -f "$tmp_queue" ]] || ! grep -q '[^[:space:]]' "$tmp_queue"; then
    echo "ERROR: yt-dlp could not extract playlist entries" >> "$YTPL_LOG"
    cat >> "$YTPL_LOG" <<'EOLOG'
COOKIE EXPORT INSTRUCTIONS (no 3rd-party extensions)
You need a Netscape-format cookies.txt file for yt-dlp at:
  ${YTDLP_COOKIES_PATH}

Two safe ways to obtain it without installing an extension:
A) Use yt-dlp to export cookies from your local browser (preferred):
   yt-dlp --cookies-from-browser chrome --cookies "${YTDLP_COOKIES_PATH}"

B) Manually export cookies via DevTools as Netscape-format cookies.txt
EOLOG
    cat <<MSG
yt-dlp needs cookies to access this playlist (YouTube is asking you to sign in).
Create a cookies.txt at ${YTDLP_COOKIES_PATH}, chmod 600, then re-run:
  ytpl start <playlist_url> -v
See ${YTPL_LOG} for details.
MSG
    return 1
  fi

  # 5. Convert video IDs to full URLs, filter empty lines
  awk -F'|' '{ if($2!="") print "https://www.youtube.com/watch?v="$2 }' "$tmp_queue" > "$YTPL_PLAYLIST"

  # Optional shuffle
  if [[ -n "$shuffle_flag" ]]; then
    shuf -o "$YTPL_PLAYLIST" "$YTPL_PLAYLIST"
    echo "Playlist shuffled" >> "$YTPL_LOG"
  fi

  # Save queue with title|url for player/show purposes
  mv "$tmp_queue" "$YTPL_QUEUE"
  echo "Playlist built successfully with $(wc -l < "$YTPL_PLAYLIST") items" >> "$YTPL_LOG"

  return 0
}


# ------------------------- basic helpers -------------------------
is_running() {
  if [[ -f "$YTPL_PID" ]]; then
    local pid; pid=$(cat "$YTPL_PID" 2>/dev/null || echo "")
    if [[ -n "$pid" ]]; then
      if kill -0 "$pid" 2>/dev/null; then
        echo "$pid"
        return 0
      else
        rm -f "$YTPL_PID"
        return 1
      fi
    else
      rm -f "$YTPL_PID"
      return 1
    fi
  fi
  return 1
}

playlist_nonempty() {
  [[ -f "$YTPL_PLAYLIST" ]] || return 1
  if grep -q '[^[:space:]]' "$YTPL_PLAYLIST"; then
    if grep -E -q 'https?://|^ytsearch:' "$YTPL_PLAYLIST"; then return 0; else return 2; fi
  fi
  return 1
}

_check_prereqs() {
  for c in mpv yt-dlp jq socat; do
    if ! command -v "$c" >/dev/null 2>&1; then
      echo "Required program '$c' not found in PATH"
      return 1
    fi
  done
  return 0
}


# ------------------------- Main CLI -------------------------
ytpl() {
  ensure_lua
  _check_prereqs || return 1

  local sub=$1; shift
  if [[ -z "$sub" ]]; then
    cat <<'USAGE'
Usage: ytpl <command>

Commands:
  start <playlist_url> [--shuffle] [--start N] [-v|-vv] [--force] [--cookies-from-browser NAME]
  stop
  status
  logs
  cleanup
  doctor       # tests cookie extraction methods
  player <command>
USAGE
    return
  fi

  case "$sub" in
    start)
      local url="" shuffle_flag="" start_index="" ytdlp_verbose="" force_flag="" cookie_override=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --shuffle) shuffle_flag=1; shift ;;
          --start)
            if [[ $# -le 1 ]]; then echo "Error: --start requires an argument"; return 1; fi
            start_index="$2"; [[ ! "$start_index" =~ ^[0-9]+$ ]] && { echo "Error: start must be non-negative integer"; return 1; }; shift 2
            ;;
          -v) ytdlp_verbose="-v"; shift ;;
          -vv) ytdlp_verbose="-vv"; shift ;;
          --force) force_flag=1; shift ;;
          --cookies-from-browser)
            if [[ $# -le 1 ]]; then echo "Error: --cookies-from-browser requires a browser name (e.g. chrome)"; return 1; fi
            cookie_override="$2"; shift 2
            ;;
          --*) echo "Unknown option: $1 (try 'ytpl -h')"; return 1 ;;
          *) url="$1"; shift ;;
        esac
      done

      [[ -z "$url" ]] && [[ -f "$YTPL_LAST" ]] && url=$(cat "$YTPL_LAST")
      if [[ -z "$url" ]]; then echo "Usage: ytpl start <playlist_url> [--shuffle] [--start N] [-v|-vv] [--force] [--cookies-from-browser NAME]"; return 1; fi

      if [[ -d "$YTPL_LOCKDIR" && -n "$force_flag" ]]; then
        echo "Force requested: killing existing ytpl/mpv (if any) and clearing lock..."
        force_clear_lock_and_kill
      fi

      if ! acquire_lock; then
        if [[ -d "$YTPL_LOCKDIR" ]]; then local ownerpid; ownerpid=$(cat "$YTPL_LOCKDIR/owner_pid" 2>/dev/null || echo "unknown"); echo "ytpl already started by PID $ownerpid. Use --force to override."; else echo "Unable to acquire lock"; fi
        return 1
      fi

      if is_running >/dev/null; then echo "ytpl is already running (PID $(cat "$YTPL_PID"))"; release_lock; return 1; fi

      rotate_or_clear_log
      build_playlist_file "$url" "$shuffle_flag" "$ytdlp_verbose" "$cookie_override" || { release_lock; return 1; }
      echo "$url" > "$YTPL_LAST"

      playlist_nonempty
      local p_ok=$?
      if [[ $p_ok -ne 0 ]]; then
        echo "ERROR: built playlist seems empty or invalid (code $p_ok). See logs:"; tail -n 200 "$YTPL_LOG"
        [[ -f "$YTPL_PLAYLIST" ]] && echo "Playlist contents:" && sed -n '1,60p' "$YTPL_PLAYLIST"
        [[ -f "$YTPL_PID" ]] && rm -f "$YTPL_PID"
        release_lock
        return 1
      fi

      [[ -e "$YTPL_IPC" ]] && rm -f "$YTPL_IPC"
      [[ -f "$YTPL_NOWPLAYING" ]] && rm -f "$YTPL_NOWPLAYING"

      local mode_flag=""
      [[ -f "$YTPL_MODE" ]] && [[ "$(cat "$YTPL_MODE")" == "audio" ]] && mode_flag="--no-video"

      local mpv_args=( $mode_flag --ytdl=yes --ytdl-format="bestaudio/best" --loop-playlist=no --input-ipc-server="$YTPL_IPC" --idle=no --no-terminal --script="$YTPL_LUA" --save-position-on-quit=no --msg-level=all=info --log-file="$YTPL_LOG" )
      [[ -n "$start_index" ]] && mpv_args+=( "--playlist-start=$start_index" )
      mpv_args+=( "--playlist=$YTPL_PLAYLIST" )

      # Start mpv, detached
      mpv "${(q)mpv_args[@]}" >/dev/null 2>&1 &
      local mpv_pid=$!; echo "$mpv_pid" > "$YTPL_PID"

      # Wait up to ~3s for IPC to appear (30 * 0.1)
      local waited=0 ipc_ok=0
      while [[ $waited -lt 30 ]]; do
        if kill -0 "$mpv_pid" 2>/dev/null; then
          if [[ -S "$YTPL_IPC" ]]; then ipc_ok=1; break; fi
        else
          break
        fi
        sleep 0.1; waited=$((waited+1))
      done

      if [[ $ipc_ok -ne 1 ]]; then
        echo "mpv failed to start or did not create IPC. Tail logs:"; tail -n 200 "$YTPL_LOG"
        [[ -f "$YTPL_PID" ]] && rm -f "$YTPL_PID"
        release_lock
        return 1
      fi

      [[ -d "$YTPL_LOCKDIR" ]] && printf "%s\n" "$mpv_pid" > "$YTPL_LOCKDIR/mpv_pid"
      printf "\n--- ytpl START %s (PID %s) ---\n" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$mpv_pid" >> "$YTPL_LOG"
      [[ -f "$YTPL_QUEUE" ]] && { printf "Playlist (title|url):\n" >> "$YTPL_LOG"; sed -n '1,200p' "$YTPL_QUEUE" >> "$YTPL_LOG"; printf "\n" >> "$YTPL_LOG"; }

      echo "ytpl started in $(cat "$YTPL_MODE") mode (PID $mpv_pid)"
      echo "Logs: $YTPL_LOG"
      echo "Now Playing: $YTPL_NOWPLAYING"
      return 0
      ;;

    stop)
      if is_running >/dev/null; then
        local pid; pid=$(cat "$YTPL_PID")
        if kill "$pid" 2>/dev/null; then echo "ytpl stopped"; else echo "ytpl not running"; fi
        rm -f "$YTPL_PID"
      else
        echo "ytpl is not running"
      fi
      [[ -e "$YTPL_IPC" ]] && rm -f "$YTPL_IPC"
      [[ -f "$YTPL_NOWPLAYING" ]] && rm -f "$YTPL_NOWPLAYING"
      [[ -f "$YTPL_PLAYLIST" ]] && rm -f "$YTPL_PLAYLIST"
      [[ -f "$YTPL_QUEUE" ]] && rm -f "$YTPL_QUEUE"
      release_lock
      ;;

    status)
      if is_running >/dev/null; then
        local pid; pid=$(cat "$YTPL_PID")
        # uptime in seconds (elapsed)
        if command -v ps >/dev/null 2>&1; then
          local etimes; etimes=$(ps -p "$pid" -o etimes= 2>/dev/null || echo "")
        else
          local etimes=""
        fi
        if [[ -n "$etimes" ]]; then
          local mins=$(( etimes / 60 )); local hrs=$(( mins / 60 )); local remmin=$(( mins % 60 ))
          printf "ytpl is running (PID %s) — uptime: %dh%02dm\n" "$pid" "$hrs" "$remmin"
        else
          echo "ytpl is running (PID $pid)"
        fi
        echo "Last log lines:"
        [[ -f "$YTPL_LOG" ]] && tail -n 10 "$YTPL_LOG"
      else
        echo "ytpl is not running"
      fi
      ;;

    logs)
      [[ -f "$YTPL_LOG" ]] && tail -n 50 "$YTPL_LOG" || echo "No logs found."
      ;;

    cleanup)
      echo "Cleanup: killing mpv if recorded and clearing lock/pid"
      force_clear_lock_and_kill
      echo "Cleanup done."
      ;;

    doctor)
      echo "ytpl doctor: checking cookie extraction methods..."
      if [[ -f "$YTDLP_COOKIES_PATH" ]]; then
        echo "Explicit cookie file found: $YTDLP_COOKIES_PATH"
      else
        echo "No explicit cookie file at: $YTDLP_COOKIES_PATH"
      fi

      local test_url="https://www.youtube.com/playlist?list=PLAOCHv-zAmkge9fu4Ii6E6aKFBnnT7Egc"  # guaranteed public video
      for b in chrome firefox chromium vivaldi zen brave edge opera whale; do
        echo -n "Trying browser: $b ... "
        if yt-dlp --cookies-from-browser "$b" -j "$test_url" >/dev/null 2>>"$YTPL_LOG"; then
          echo "OK (browser: $b)"
        else
          echo "failed"
        fi
      done

      echo "Check $YTPL_LOG for details."
      ;;

    player)
      if [[ $# -eq 0 ]]; then
        cat <<'PHELP'
Usage: ytpl player <command> [options]
Commands:
  play            Toggle play/pause
  pause           Toggle play/pause
  stop            Quit mpv
  next            Skip to next track (ensures start at 0:00)
  prev            Go to previous track (ensures start at 0:00)
  volume-up       Increase volume by 5%
  volume-down     Decrease volume by 5%
  seek-forward    Seek forward 10s
  seek-backward   Seek backward 10s
  mode audio|video
  show            Show current track and queue context (prev 2 / current / next 3)
PHELP
        return
      fi

      if [[ ! -S "$YTPL_IPC" ]]; then echo "ytpl player: IPC socket not found. Is ytpl running?"; return 1; fi

      local cmd=$1; shift
      case "$cmd" in
        play|pause) mpv_ipc '{ "command": ["cycle", "pause"] }' && echo "OK: toggled play/pause" || echo "Error" ;;
        stop) mpv_ipc '{ "command": ["quit"] }' && echo "OK: quit sent" || echo "Error" ;;
        next)
          local before pos_after; before=$(mpv_get_prop "playlist-pos" 2>/dev/null || echo "")
          mpv_ipc '{ "command": ["playlist-next", "force"] }'
          local i=0
          while [[ $i -lt 20 ]]; do
            sleep 0.05
            pos_after=$(mpv_get_prop "playlist-pos" 2>/dev/null || echo "")
            if [[ -n "$pos_after" && "$pos_after" != "$before" ]]; then
              mpv_ipc '{ "command": ["set_property", "time-pos", 0] }' >/dev/null 2>&1
              echo "OK: next -> pos=$pos_after"
              break
            fi
            i=$((i+1))
          done
          [[ $i -ge 20 ]] && echo "Warning: next may not have taken effect; check logs."
        ;;
        prev)
          local before pos_after; before=$(mpv_get_prop "playlist-pos" 2>/dev/null || echo "")
          mpv_ipc '{ "command": ["playlist-prev", "force"] }'
          local i=0
          while [[ $i -lt 20 ]]; do
            sleep 0.05
            pos_after=$(mpv_get_prop "playlist-pos" 2>/dev/null || echo "")
            if [[ -n "$pos_after" && "$pos_after" != "$before" ]]; then
              mpv_ipc '{ "command": ["set_property", "time-pos", 0] }' >/dev/null 2>&1
              echo "OK: prev -> pos=$pos_after"
              break
            fi
            i=$((i+1))
          done
          [[ $i -ge 20 ]] && echo "Warning: prev may not have taken effect; check logs."
        ;;
        volume-up) mpv_ipc '{ "command": ["add", "volume", 5] }' && echo "OK: volume up" || echo "Error" ;;
        volume-down) mpv_ipc '{ "command": ["add", "volume", -5] }' && echo "OK: volume down" || echo "Error" ;;
        seek-forward) mpv_ipc '{ "command": ["seek", 10, "relative"] }' && echo "OK: seek forward" || echo "Error" ;;
        seek-backward) mpv_ipc '{ "command": ["seek", -10, "relative"] }' && echo "OK: seek backward" || echo "Error" ;;
        mode) local newmode=$1; [[ "$newmode" != "audio" && "$newmode" != "video" ]] && { echo "Usage: ytpl player mode {audio|video}"; return 1; }; echo "$newmode" > "$YTPL_MODE"; echo "Mode switched to $newmode. Restart ytpl to apply." ;;
        show)
          local current="Unknown"
          [[ -f "$YTPL_NOWPLAYING" ]] && current=$(cat "$YTPL_NOWPLAYING")

          echo "Current track: $current"

          # Try mpv IPC first
          local playlist_json pos
          playlist_json=$(printf '{ "command": ["get_property", "playlist"] }' | socat - "$YTPL_IPC" 2>/dev/null)
          pos=$(printf '{ "command": ["get_property", "playlist-pos"] }' | socat - "$YTPL_IPC" 2>/dev/null | jq -r '.data // empty' 2>/dev/null)

          if [[ -n "$playlist_json" && "$playlist_json" != "{}" ]]; then
            # Zsh 1-based array
            IFS=$'\n' read -r -d '' -A titles < <(echo "$playlist_json" | jq -r '.data[]?.filename' && printf '\0')
            local start=$(( pos - 1 - 2 < 0 ? 0 : pos - 1 - 2 ))  # prev 2
            local end=$(( pos - 1 + 3 >= ${#titles[@]} ? ${#titles[@]}-1 : pos - 1 + 3 ))  # next 3
            echo "Queue context (prev 2 / current / next 3):"
            for i in $(seq $start $end); do
              if [[ $i -eq $(( pos - 1 )) ]]; then
                echo "▶ ${titles[$((i+1))]}"  # +1 because titles[] is 1-based
              else
                echo "  ${titles[$((i+1))]}"
              fi
            done
          elif [[ -f "$YTPL_QUEUE" ]]; then
            # fallback: local queue
            local -a qtitles urls
            local idx=1 found=-1 total
            while IFS='|' read -r t u; do
              qtitles[idx]="$t"
              urls[idx]="$u"
              [[ "$t" == "$current" ]] && found=$idx
              idx=$((idx+1))
            done < "$YTPL_QUEUE"

            total=${#qtitles[@]}

            if [[ $found -eq -1 ]]; then
              echo "Queue available but current track not found in local queue."
              return 0
            fi

            local start=$(( found - 2 < 1 ? 1 : found - 2 ))
            local end=$(( found + 3 > total ? total : found + 3 ))

            echo "Queue context (prev 2 / current / next 3):"
            for i in $(seq $start $end); do
              if [[ $i -eq $found ]]; then
                echo "▶ ${qtitles[$i]}"
              else
                echo "  ${qtitles[$i]}"
              fi
            done
          else
            echo "Queue not available."
          fi
        ;;
        *) echo "ytpl player: Unknown command '$cmd'. Run 'ytpl player' for help." ;;
      esac
      ;;

    *)
      echo "Unknown subcommand: $sub"
      echo "Try 'ytpl -h' or 'ytpl' for usage."
      return 1
      ;;
  esac
}
