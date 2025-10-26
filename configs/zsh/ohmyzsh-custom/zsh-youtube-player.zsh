#!/usr/bin/env zsh
# ytpl - YouTube Playlist Audio/Video Daemon (full deterministic queue version)

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

LOCK_STALE_SECS=$((30*60))
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
  local url="$1" shuffle_flag="$2" ytdlp_verbose="$3" cookie_override="$4"

  [[ -f "$YTPL_QUEUE" ]] && rm -f "$YTPL_QUEUE"
  [[ -f "$YTPL_PLAYLIST" ]] && rm -f "$YTPL_PLAYLIST"

  # Helper: extract playlist into tmp file
  _extract_playlist() {
    local extra_args=()
    [[ -n "$1" ]] && extra_args=(--cookies-from-browser "$1")
    [[ -f "$YTDLP_COOKIES_PATH" ]] && extra_args=(--cookies "$YTDLP_COOKIES_PATH")

    yt-dlp "${extra_args[@]}" $ytdlp_verbose -j --flat-playlist "$url" 2>>"$YTPL_LOG" |
      jq -r '.title + "|" + .url' > "${YTPL_QUEUE}.tmp"
  }

  if [[ -n "$cookie_override" ]]; then
    echo "Attempting cookie extraction from browser (forced): $cookie_override" >> "$YTPL_LOG"
    if _extract_playlist "$cookie_override"; then
      mv "${YTPL_QUEUE}.tmp" "$YTPL_QUEUE"
    else
      echo "Forced browser cookie extraction failed for '$cookie_override'." >> "$YTPL_LOG"
      [[ -f "${YTPL_QUEUE}.tmp" ]] && rm -f "${YTPL_QUEUE}.tmp"
    fi
  fi

  if [[ ! -f "$YTPL_QUEUE" && -f "$YTDLP_COOKIES_PATH" ]]; then
    echo "Using explicit cookie file: $YTDLP_COOKIES_PATH" >> "$YTPL_LOG"
    if _extract_playlist; then
      mv "${YTPL_QUEUE}.tmp" "$YTPL_QUEUE"
    else
      echo "yt-dlp with explicit cookies failed; trying browser cookie extraction." >> "$YTPL_LOG"
      [[ -f "${YTPL_QUEUE}.tmp" ]] && rm -f "${YTPL_QUEUE}.tmp"
    fi
  fi

  if [[ ! -f "$YTPL_QUEUE" ]]; then
    local -a browsers=(firefox chromium vivaldi zen brave chrome edge opera whale)
    for b in "${browsers[@]}"; do
      echo "Trying cookies from browser: $b" >> "$YTPL_LOG"
      if _extract_playlist "$b"; then
        echo "yt-dlp: succeeded with browser '$b' cookies" >> "$YTPL_LOG"
        mv "${YTPL_QUEUE}.tmp" "$YTPL_QUEUE"
        break
      else
        echo "yt-dlp: browser '$b' failed; trying next candidate" >> "$YTPL_LOG"
        [[ -f "${YTPL_QUEUE}.tmp" ]] && rm -f "${YTPL_QUEUE}.tmp"
      fi
    done
  fi

  if [[ ! -f "$YTPL_QUEUE" ]]; then
    echo "ERROR: yt-dlp could not extract playlist entries" >> "$YTPL_LOG"
    return 1
  fi

  # ----------------------- Build clean playlist -----------------------
  # Normalize URLs and only include non-empty ones
  awk -F'|' '
    $2 != "" && $2 !~ /^$/ {
      url=$2

      # Convert music.youtube.com links to www.youtube.com/watch?v=
      gsub("^https?://music.youtube.com/watch\\?v=", "https://www.youtube.com/watch?v=", url)

      # Convert music.youtube.com playlist links to empty (skip them)
      if (url ~ "^https?://music.youtube.com/playlist") next

      # Strip unnecessary query params except "v" if present
      if (url ~ "^https?://www.youtube.com/watch\\?v=") {
        split(url, parts, "&")
        url=parts[1]
      }

      print url
    }
  ' "$YTPL_QUEUE" > "$YTPL_PLAYLIST"

  # Shuffle if requested
  if [[ -n "$shuffle_flag" ]]; then
    shuf "$YTPL_PLAYLIST" -o "$YTPL_PLAYLIST"
  fi

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

# ------------------------- Queue helpers (mpv-synced) -------------------------
# Use $YTPL_PLAYLIST as source, query mpv for current index

queue_len() {
  [[ -f "$YTPL_PLAYLIST" ]] && wc -l < "$YTPL_PLAYLIST" || echo 0
}

queue_get() {
  local idx=$1
  [[ -f "$YTPL_PLAYLIST" ]] || return
  sed -n "$(( idx + 1 ))p" "$YTPL_PLAYLIST"
}

queue_current_idx() {
  local idx
  idx=$(mpv_get_prop playlist-pos)
  [[ -n "$idx" && "$idx" =~ ^[0-9]+$ ]] && echo "$idx" || echo 0
}

queue_current() {
  local idx=$(queue_current_idx)
  queue_get "$idx"
}

queue_prev() {
  local idx=$(queue_current_idx)
  [[ $idx -gt 0 ]] && idx=$(( idx - 1 ))
  queue_get "$idx"
}

queue_next() {
  local idx=$(queue_current_idx)
  local len=$(queue_len)
  [[ $idx -lt $((len - 1)) ]] && idx=$(( idx + 1 ))
  queue_get "$idx"
}

# ------------------------- Player commands -------------------------
player_cmd() {
  local cmd=$1; shift
  [[ ! -S "$YTPL_IPC" ]] && echo "ytpl player: IPC not found. Is ytpl running?" && return 1

  case "$cmd" in
    play|pause) mpv_ipc '{ "command": ["cycle", "pause"] }' && echo "OK: toggled play/pause" ;; 
    stop) mpv_ipc '{ "command": ["quit"] }' && echo "OK: quit sent" ;; 
    next)
      # get next non-empty track
      local cur_idx=$(queue_current_idx)
      local len=$(queue_len)
      local next_idx=$((cur_idx + 1))
      while [[ $next_idx -lt $len && -z "$(queue_get $next_idx)" ]]; do
        next_idx=$((next_idx + 1))
      done
      [[ $next_idx -ge $len ]] && next_idx=$((len - 1))

      mpv_ipc "{ \"command\": [\"playlist-play-index\", $next_idx] }"
      mpv_ipc '{ "command": ["set_property", "time-pos", 0] }' >/dev/null 2>&1
      echo "OK: moved to next track"
      ;;

    prev)
      # get previous non-empty track
      local cur_idx=$(queue_current_idx)
      local prev_idx=$((cur_idx - 1))
      while [[ $prev_idx -ge 0 && -z "$(queue_get $prev_idx)" ]]; do
        prev_idx=$((prev_idx - 1))
      done
      [[ $prev_idx -lt 0 ]] && prev_idx=0

      mpv_ipc "{ \"command\": [\"playlist-play-index\", $prev_idx] }"
      mpv_ipc '{ "command": ["set_property", "time-pos", 0] }' >/dev/null 2>&1
      echo "OK: moved to previous track"
      ;;
    volume-up) mpv_ipc '{ "command": ["add", "volume", 5] }' && echo "OK: volume up" ;; 
    volume-down) mpv_ipc '{ "command": ["add", "volume", -5] }' && echo "OK: volume down" ;; 
    set-volume)
      local vol="$1"
      if [[ -z "$vol" || ! "$vol" =~ ^[0-9]+$ || "$vol" -lt 0 || "$vol" -gt 100 ]]; then
        echo "Usage: ytpl player set-volume <0-100>"
        return 1
      fi
      mpv_ipc "{ \"command\": [\"set_property\", \"volume\", $vol] }" && echo "OK: volume set to $vol%" ;;
    seek-forward) mpv_ipc '{ "command": ["seek", 10, "relative"] }' && echo "OK: seek forward" ;; 
    seek-backward) mpv_ipc '{ "command": ["seek", -10, "relative"] }' && echo "OK: seek backward" ;; 
    mode) 
      local newmode=$1
      [[ "$newmode" != "audio" && "$newmode" != "video" ]] && { echo "Usage: ytpl player mode {audio|video}"; return 1; }
      echo "$newmode" > "$YTPL_MODE"
      echo "Mode switched to $newmode. Restart ytpl to apply." 
      ;;
    show)
      [[ ! -S "$YTPL_IPC" ]] && { echo "mpv not running or IPC missing"; return 1; }

      local total=$(queue_len)
      local cur_idx=$(queue_current_idx)
      local cur_title=$(mpv_get_prop media-title)

      echo "Queue context (prev 2 / current / next 3):"

      # Previous 2 tracks
      for offset in 2 1; do
        local i=$(( cur_idx - offset ))
        [[ $i -ge 0 ]] || continue
        echo "  $(queue_get $i)"
      done

      # Current track
      echo "▶ ${cur_title:-$(queue_get $cur_idx)}"

      # Next 3 tracks
      for offset in 1 2 3; do
        local i=$(( cur_idx + offset ))
        [[ $i -lt $total ]] || continue
        echo "  $(queue_get $i)"
      done
      ;;
    *) echo "Unknown player command '$cmd'. Run 'ytpl player' for help." ;; 
  esac
}

# ------------------------- Main CLI -------------------------
ytpl() {
  local sub=$1; shift
  [[ -z "$sub" ]] && { echo "Usage: ytpl <command>"; return 1; }

  case "$sub" in
    player)
      if [[ $# -eq 0 ]]; then
        cat <<'PHELP'
Usage: ytpl player <command> [options]
Commands:
  play                Toggle play/pause
  pause               Toggle play/pause
  stop                Quit mpv
  next                Skip to next track (ensures start at 0:00)
  prev                Go to previous track (ensures start at 0:00)
  volume-up           Increase volume by 5%
  volume-down         Decrease volume by 5%
  set-volume <0-100>  Set volume between 0% and 100%
  seek-forward        Seek forward 10s
  seek-backward       Seek backward 10s
  mode audio|video
  show                Show current track and queue context (prev 2 / current / next 3)
PHELP
        return
      fi

      player_cmd "$@" ;; 

    start)
      # ------------------ Parse CLI options ------------------
      local url="" shuffle_flag="" start_index=0 ytdlp_verbose="" force_flag=0 cookie_override=""

      if [[ $# -eq 0 ]]; then
        if [[ -z "$url" && -f "$YTPL_LAST" ]]; then
          url=$(cat "$YTPL_LAST")
        else
          echo "Usage: ytpl start <playlist_url> [--shuffle] [--start n] [-v|-vv] [--force] [--cookies-from-browser name]"
          return 1
        fi
      fi

      while [[ $# -gt 0 ]]; do
        case "$1" in
          --shuffle) shuffle_flag=1; shift ;;
          --start)
            if [[ $# -lt 2 ]]; then
              echo "error: --start requires an argument"
              return 1
            fi
            start_index="$2"
            if [[ ! "$start_index" =~ ^[0-9]+$ ]]; then
              echo "error: start must be a non-negative integer"
              return 1
            fi
            shift 2
            ;;
          -v) ytdlp_verbose="-v"; shift ;;
          -vv) ytdlp_verbose="-vv"; shift ;;
          --force) force_flag=1; shift ;;
          --cookies-from-browser)
            if [[ $# -lt 2 ]]; then
              echo "error: --cookies-from-browser requires a browser name (e.g. chrome)"
              return 1
            fi
            cookie_override="$2"
            shift 2
            ;;
          --*) echo "unknown option: $1 (try 'ytpl -h')"; return 1 ;;
          *)
            if [[ -z "$url" ]]; then
              url="$1"
            else
              echo "unexpected argument: $1"
              return 1
            fi
            shift
            ;;
        esac
      done

      # ------------------ Fallback to last playlist ------------------
      if [[ -z "$url" && -f "$YTPL_LAST" ]]; then
        url=$(cat "$YTPL_LAST")
      fi
      if [[ -z "$url" ]]; then
        echo "usage: ytpl start <playlist_url> [--shuffle] [--start n] [-v|-vv] [--force] [--cookies-from-browser name]"
        return 1
      fi

      # ------------------ Force clear lock if requested ------------------
      if [[ -d "$YTPL_LOCKDIR" && "$force_flag" -eq 1 ]]; then
        echo "force requested: killing existing ytpl/mpv (if any) and clearing lock..."
        force_clear_lock_and_kill
      fi

      if ! acquire_lock; then
        if [[ -d "$YTPL_LOCKDIR" ]]; then
          local ownerpid=$(cat "$YTPL_LOCKDIR/owner_pid" 2>/dev/null || echo "unknown")
          echo "ytpl already started by pid $ownerpid. use --force to override."
        else
          echo "unable to acquire lock"
        fi
        return 1
      fi

      # ------------------ Rotate logs & build playlist ------------------
      rotate_or_clear_log
      build_playlist_file "$url" "$shuffle_flag" "$ytdlp_verbose" "$cookie_override" || { release_lock; return 1; }
      echo "$url" > "$YTPL_LAST"

      # ------------------ Validate playlist ------------------
      playlist_nonempty
      local p_ok=$?
      if [[ $p_ok -ne 0 ]]; then
        echo "error: built playlist seems empty or invalid (code $p_ok). see logs:"
        [[ -f "$YTPL_LOG" ]] && tail -n 50 "$YTPL_LOG"
        [[ -f "$YTPL_PLAYLIST" ]] && echo "playlist contents:" && sed -n '1,60p' "$YTPL_PLAYLIST"
        [[ -f "$YTPL_PID" ]] && rm -f "$YTPL_PID"
        release_lock
        return 1
      fi

      # ------------------ Cleanup old IPC / nowplaying ------------------
      [[ -e "$YTPL_IPC" ]] && rm -f "$YTPL_IPC"
      [[ -f "$YTPL_NOWPLAYING" ]] && rm -f "$YTPL_NOWPLAYING"

      # ------------------ Determine mode ------------------
      local mode_flag=""
      [[ -f "$YTPL_MODE" ]] && [[ "$(cat "$YTPL_MODE")" == "audio" ]] && mode_flag="--no-video"

      # ------------------ mpv arguments ------------------
      local mpv_args=( $mode_flag --ytdl=yes --ytdl-format="bestaudio/best" --loop-playlist=no --input-ipc-server="$YTPL_IPC" --idle=no --no-terminal --script="$YTPL_LUA" --save-position-on-quit=no --msg-level=all=info --log-file="$YTPL_LOG" )
      [[ "$start_index" -gt 0 ]] && mpv_args+=( "--playlist-start=$start_index" )
      mpv_args+=( "--playlist=$YTPL_PLAYLIST" )

      # ------------------ Start mpv ------------------
      mpv "${(q)mpv_args[@]}" >/dev/null 2>&1 &
      local MPV_PID=$!; echo "$MPV_PID" > "$YTPL_PID"

      # wait up to ~3s for ipc to appear
      local waited=0 ipc_ok=0
      while [[ $waited -lt 30 ]]; do
        if kill -0 "$MPV_PID" 2>/dev/null; then
          if [[ -S "$YTPL_IPC" ]]; then ipc_ok=1; break; fi
        else
          break
        fi
        sleep 0.1
        waited=$((waited+1))
      done

      if [[ $ipc_ok -ne 1 ]]; then
        echo "mpv failed to start or did not create IPC. Tail logs:"
        [[ -f "$YTPL_LOG" ]] && tail -n 50 "$YTPL_LOG"
        [[ -f "$YTPL_PID" ]] && rm -f "$YTPL_PID"
        release_lock
        return 1
      fi

      # ------------------ Record mpv PID in lockdir ------------------
      [[ -d "$YTPL_LOCKDIR" ]] && printf "%s\n" "$MPV_PID" > "$YTPL_LOCKDIR/mpv_pid"

      # ------------------ Log playlist info ------------------
      printf "\n--- ytpl start %s (pid %s) ---\n" "$(date -u +"%y-%m-%dt%H:%M:%SZ")" "$MPV_PID" >> "$YTPL_LOG"
      [[ -f "$YTPL_QUEUE" ]] && {
        printf "playlist (title|url):\n" >> "$YTPL_LOG"
        sed -n '1,200p' "$YTPL_QUEUE" >> "$YTPL_LOG"
        printf "\n" >> "$YTPL_LOG"
      }

      local n_tracks=$(queue_len)
      # ------------------ Final message ------------------
      echo "ytpl started in $(cat "$YTPL_MODE") mode (pid $MPV_PID)"
      echo "logs: $YTPL_LOG"
      echo "now playing: $YTPL_NOWPLAYING"
      echo "playlist loaded: $n_tracks tracks"
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
          printf "ytpl is running (pid %s) — uptime: %dh%02dm\n" "$pid" "$hrs" "$remmin"
        else
          echo "ytpl is running (pid $pid)"
        fi
        echo "last log lines:"
        [[ -f "$YTPL_LOG" ]] && tail -n 10 "$YTPL_LOG"
      else
        echo "ytpl is not running"
      fi
      ;;

    logs)
      [[ -f "$YTPL_LOG" ]] && tail -n 50 "$YTPL_LOG" || echo "no logs found."
      ;;

    cleanup)
      echo "cleanup: killing mpv if recorded and clearing lock/pid"
      force_clear_lock_and_kill
      echo "cleanup done."
      ;;

    doctor)
      echo "ytpl doctor: checking cookie extraction methods..."
      if [[ -f "$YTDLP_COOKIES_PATH" ]]; then
        echo "Explicit cookie file found: $YTDLP_COOKIES_PATH"
      else
        echo "No explicit cookie file at: $YTDLP_COOKIES_PATH"
      fi

      local TEST_URL="https://www.youtube.com/playlist?list=PLAOCHv-zAmkge9fu4Ii6E6aKFBnnT7Egc"  # guaranteed public video
      for b in firefox chromium vivaldi zen brave edge chrome opera whale; do
        echo -n "Trying browser: $b ... "
        if yt-dlp --cookies-from-browser "$b" -j "$TEST_URL" >/dev/null 2>>"$YTPL_LOG"; then
          echo "OK (browser: $b)"
        else
          echo "failed"
        fi
      done

      echo "Check $YTPL_LOG for details."
      ;;

    *) echo "Unknown subcommand: $sub"; return 1 ;; 
  esac
}
