#!/usr/bin/env zsh
# ytpl - YouTube Playlist Audio/Video Daemon
# Features:
#  - Start playlists with optional --shuffle and --start N (0-based)
#  - mpv logging to /tmp/ytpl.log (rotates/truncates at 200MB)
#  - yt-dlp extraction runs with -v/-vv during playlist build and appends stderr to log
#  - cookies auto-detection: explicit cookies.txt, then browsers (chrome, firefox, chromium, vivaldi, zen)
#  - Lua hook ensures tracks start at 0:00 and writes now-playing
#  - Robust player controls via mpv IPC; next/prev forcibly reset time-pos
#  - Uses /tmp lockdir; supports --force and cleanup

# ---------- prerequisites (no runtime commands at source except mkdir) ----------
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

mkdir -p "$YTPL_DIR"
export YTPL_NOWPLAYING

# ---------- embed minimal Lua (created on-demand) ----------
ensure_lua() {
  [[ -f "$YTPL_LUA" ]] && return 0
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
}

# ---------- logging rotation ----------
rotate_or_clear_log() {
  local max=$((200 * 1024 * 1024))  # 200 MB
  if [[ -f "$YTPL_LOG" ]]; then
    if stat --version >/dev/null 2>&1; then
      size=$(stat -c%s "$YTPL_LOG" 2>/dev/null || echo 0)
    else
      size=$(wc -c < "$YTPL_LOG" 2>/dev/null || echo 0)
    fi
    if [[ -n "$size" && "$size" -ge "$max" ]]; then
      mv "$YTPL_LOG" "${YTPL_LOG}.$(date +%s)"
      : > "$YTPL_LOG"
    else
      : > "$YTPL_LOG"
    fi
  else
    : > "$YTPL_LOG"
  fi
}

# ---------- simple lockdir (in /tmp) ----------
acquire_lock() {
  if mkdir "$YTPL_LOCKDIR" 2>/dev/null; then
    printf "%s\n" "$$" > "$YTPL_LOCKDIR/owner_pid"
    return 0
  fi
  local ownerpid mpvpid
  if [[ -f "$YTPL_LOCKDIR/owner_pid" ]]; then ownerpid=$(cat "$YTPL_LOCKDIR/owner_pid" 2>/dev/null || echo ""); fi
  if [[ -f "$YTPL_LOCKDIR/mpv_pid" ]]; then mpvpid=$(cat "$YTPL_LOCKDIR/mpv_pid" 2>/dev/null || echo ""); fi

  if [[ -n "$ownerpid" ]]; then
    if kill -0 "$ownerpid" 2>/dev/null; then
      return 1
    fi
  fi

  rm -rf "$YTPL_LOCKDIR"
  if mkdir "$YTPL_LOCKDIR" 2>/dev/null; then
    printf "%s\n" "$$" > "$YTPL_LOCKDIR/owner_pid"
    return 0
  fi
  return 2
}

release_lock() {
  if [[ ! -d "$YTPL_LOCKDIR" ]]; then return 0; fi
  local ownerpid mpvpid remove=0
  ownerpid=$(cat "$YTPL_LOCKDIR/owner_pid" 2>/dev/null || echo "")
  mpvpid=$(cat "$YTPL_LOCKDIR/mpv_pid" 2>/dev/null || echo "")
  if [[ "$ownerpid" == "$$" ]] || [[ -z "$ownerpid" ]]; then remove=1; fi
  if [[ -n "$ownerpid" ]]; then
    if ! kill -0 "$ownerpid" 2>/dev/null; then remove=1; fi
  fi
  if [[ -n "$mpvpid" ]]; then
    if ! kill -0 "$mpvpid" 2>/dev/null; then remove=1; fi
  fi
  if [[ $remove -eq 1 ]]; then rm -rf "$YTPL_LOCKDIR"; fi
}

force_clear_lock_and_kill() {
  if [[ -d "$YTPL_LOCKDIR" ]]; then
    local mpvpid
    mpvpid=$(cat "$YTPL_LOCKDIR/mpv_pid" 2>/dev/null || echo "")
    if [[ -n "$mpvpid" ]]; then
      if kill -0 "$mpvpid" 2>/dev/null; then
        kill "$mpvpid" 2>/dev/null || true
        sleep 0.15
        if kill -0 "$mpvpid" 2>/dev/null; then kill -9 "$mpvpid" 2>/dev/null || true; fi
      fi
    fi
    rm -rf "$YTPL_LOCKDIR"
  fi
  if [[ -f "$YTPL_PID" ]]; then
    local pid; pid=$(cat "$YTPL_PID" 2>/dev/null || echo "")
    if [[ -n "$pid" ]]; then
      if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null || true
        sleep 0.15
        if kill -0 "$pid" 2>/dev/null; then kill -9 "$pid" 2>/dev/null || true; fi
      fi
    fi
    rm -f "$YTPL_PID"
  fi
}

# ---------- mpv IPC helpers ----------
mpv_ipc() {
  if [[ ! -S "$YTPL_IPC" ]]; then return 2; fi
  printf '%s\n' "$1" | socat - "$YTPL_IPC" 2>/dev/null
  return $?
}

mpv_get_prop() {
  local prop="$1"
  if [[ ! -S "$YTPL_IPC" ]]; then echo ""; return 1; fi
  printf '{ "command": ["get_property", "%s"] }' "$prop" | socat - "$YTPL_IPC" 2>/dev/null | jq -r '.data // empty' 2>/dev/null
}

# ---------- build playlist: cookie autodetect + extraction ----------
build_playlist_file() {
  local url="$1" shuffle_flag="$2" ytdlp_verbose="$3"
  [[ -f "$YTPL_QUEUE" ]] && rm -f "$YTPL_QUEUE"
  [[ -f "$YTPL_PLAYLIST" ]] && rm -f "$YTPL_PLAYLIST"

  # preferred explicit cookie file first
  if [[ -f "$YTDLP_COOKIES_PATH" ]]; then
    ytdlp_cookie_args=( --cookies "$YTDLP_COOKIES_PATH" )
    echo "Using explicit cookie file: $YTDLP_COOKIES_PATH" >> "$YTPL_LOG"
    if yt-dlp $ytdlp_verbose "${ytdlp_cookie_args[@]}" -j --flat-playlist "$url" 2>>"$YTPL_LOG" | jq -r '.title + "|" + .url' > "${YTPL_QUEUE}.tmp" 2>>"$YTPL_LOG"; then
      mv "${YTPL_QUEUE}.tmp" "$YTPL_QUEUE"
      cut -d'|' -f2 "$YTPL_QUEUE" > "$YTPL_PLAYLIST"
      return 0
    else
      echo "yt-dlp with explicit cookies failed; will try browser cookie extraction. See log for details." >> "$YTPL_LOG"
      [[ -f "${YTPL_QUEUE}.tmp" ]] && rm -f "${YTPL_QUEUE}.tmp"
    fi
  fi

  # browsers to try (in order requested)
  local -a browsers=("chrome" "firefox" "chromium" "vivaldi" "zen")

  for b in "${browsers[@]}"; do
    echo "Trying cookies from browser: $b" >> "$YTPL_LOG"
    # Attempt extraction using --cookies-from-browser $b
    if yt-dlp $ytdlp_verbose --cookies-from-browser "$b" -j --flat-playlist "$url" 2>>"$YTPL_LOG" | jq -r '.title + "|" + .url' > "${YTPL_QUEUE}.tmp" 2>>"$YTPL_LOG"; then
      echo "yt-dlp: succeeded with browser '$b' cookies" >> "$YTPL_LOG"
      mv "${YTPL_QUEUE}.tmp" "$YTPL_QUEUE"
      cut -d'|' -f2 "$YTPL_QUEUE" > "$YTPL_PLAYLIST"
      return 0
    else
      # check for unsupported-browser kind of message (optional debug)
      echo "yt-dlp: browser '$b' failed; trying next candidate" >> "$YTPL_LOG"
      [[ -f "${YTPL_QUEUE}.tmp" ]] && rm -f "${YTPL_QUEUE}.tmp"
      continue
    fi
  done

  # If we reach here, none of the cookie methods worked
  echo "ERROR: yt-dlp could not extract playlist entries (cookies missing or browser extraction failed)" >> "$YTPL_LOG"
  cat >> "$YTPL_LOG" <<EOF
Hint: For videos that require authentication (YouTube Music / gated content)
you must provide cookies. Create a cookie file at:
  $YTDLP_COOKIES_PATH

You can export cookies using yt-dlp itself (example for Chrome):
  yt-dlp --cookies-from-browser chrome --cookies "$YTDLP_COOKIES_PATH"

Or use browser extension "cookies.txt" to export cookies and save to the path above.
Make sure file is readable by your user and protected:
  chmod 600 $YTDLP_COOKIES_PATH

After creating cookies file retry:
  ytpl start <playlist_url> -v

EOF

  # also print a friendly message to user (stdout)
  cat <<MSG
yt-dlp needs cookies to access this playlist (YouTube is asking you to sign in).
I tried auto-reading browser cookies (chrome, firefox, chromium, vivaldi, zen) and no method worked.

Please create a cookies file and place it at:
  $YTDLP_COOKIES_PATH

You can export it with yt-dlp:
  yt-dlp --cookies-from-browser chrome --cookies "$YTDLP_COOKIES_PATH"

Then re-run:
  ytpl start <playlist_url> -v

(See /tmp/ytpl.log for details.)
MSG

  return 1
}

# ---------- small helpers ----------
is_running() {
  if [[ -f "$YTPL_PID" ]]; then
    local pid; pid=$(cat "$YTPL_PID" 2>/dev/null || echo "")
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      echo "$pid"; return 0
    else
      rm -f "$YTPL_PID"; return 1
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

# ---------- main (call ytpl) ----------
ytpl() {
  ensure_lua
  _check_prereqs || return 1

  local sub=$1; shift
  if [[ -z "$sub" ]]; then
    cat <<'USAGE'
Usage: ytpl <command>

Commands:
  start <playlist_url> [--shuffle] [--start N] [-v|-vv] [--force]
  stop
  status
  logs
  cleanup
  player <command>
USAGE
    return
  fi

  case "$sub" in
    start)
      local url="" shuffle_flag="" start_index="" ytdlp_verbose="" force_flag=""
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
          --*) echo "Unknown option: $1 (try 'ytpl -h')"; return 1 ;;
          *) url="$1"; shift ;;
        esac
      done

      [[ -z "$url" ]] && [[ -f "$YTPL_LAST" ]] && url=$(cat "$YTPL_LAST")
      if [[ -z "$url" ]]; then echo "Usage: ytpl start <playlist_url> [--shuffle] [--start N] [-v|-vv] [--force]"; return 1; fi

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
      build_playlist_file "$url" "$shuffle_flag" "$ytdlp_verbose" || { release_lock; return 1; }
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

      mpv "${(q)mpv_args[@]}" >/dev/null 2>&1 &
      local mpv_pid=$!; echo "$mpv_pid" > "$YTPL_PID"

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
        [[ -e "$YTPL_IPC" ]] && rm -f "$YTPL_IPC"
        [[ -f "$YTPL_NOWPLAYING" ]] && rm -f "$YTPL_NOWPLAYING"
        [[ -f "$YTPL_PLAYLIST" ]] && rm -f "$YTPL_PLAYLIST"
        [[ -f "$YTPL_QUEUE" ]] && rm -f "$YTPL_QUEUE"
      else
        echo "ytpl is not running"
      fi
      release_lock
      ;;

    status)
      if is_running >/dev/null; then echo "ytpl is running (PID $(cat "$YTPL_PID")) in $(cat "$YTPL_MODE") mode"; else echo "ytpl is not running"; fi
      ;;

    logs)
      [[ -f "$YTPL_LOG" ]] && tail -n 30 "$YTPL_LOG" || echo "No logs found."
      ;;

    cleanup)
      echo "Cleanup: killing mpv if recorded and clearing lock/pid"
      force_clear_lock_and_kill
      echo "Cleanup done."
      ;;

    player)
      if [[ $# -eq 0 ]]; then
        cat <<'PHELP'
Usage: ytpl player <command> [options]
Commands:
  play  stop  next  prev  volume-up  volume-down  seek-forward  seek-backward  mode audio|video  show
PHELP
        return
      fi

      if [[ ! -S "$YTPL_IPC" ]]; then echo "ytpl player: IPC socket not found. Is ytpl running?"; return 1; fi

      local cmd=$1; shift
      case "$cmd" in
        play) mpv_ipc '{ "command": ["cycle", "pause"] }' && echo "OK: toggled play/pause" || echo "Error" ;;
        stop) mpv_ipc '{ "command": ["quit"] }' && echo "OK: quit sent" || echo "Error" ;;
        next)
          local before pos_after; before=$(mpv_get_prop "playlist-pos" 2>/dev/null || echo "")
          mpv_ipc '{ "command": ["playlist-next", "force"] }'
          local i=0
          while [[ $i -lt 20 ]]; do sleep 0.05; pos_after=$(mpv_get_prop "playlist-pos" 2>/dev/null || echo ""); if [[ -n "$pos_after" && "$pos_after" != "$before" ]]; then mpv_ipc '{ "command": ["set_property", "time-pos", 0] }' >/dev/null 2>&1; echo "OK: next -> pos=$pos_after"; break; fi; i=$((i+1)); done
          [[ $i -ge 20 ]] && echo "Warning: next may not have taken effect; check logs."
        ;;
        prev)
          local before pos_after; before=$(mpv_get_prop "playlist-pos" 2>/dev/null || echo "")
          mpv_ipc '{ "command": ["playlist-prev", "force"] }'
          local i=0
          while [[ $i -lt 20 ]]; do sleep 0.05; pos_after=$(mpv_get_prop "playlist-pos" 2>/dev/null || echo ""); if [[ -n "$pos_after" && "$pos_after" != "$before" ]]; then mpv_ipc '{ "command": ["set_property", "time-pos", 0] }' >/dev/null 2>&1; echo "OK: prev -> pos=$pos_after"; break; fi; i=$((i+1)); done
          [[ $i -ge 20 ]] && echo "Warning: prev may not have taken effect; check logs."
        ;;
        volume-up) mpv_ipc '{ "command": ["add", "volume", 5] }' && echo "OK: volume up" || echo "Error" ;;
        volume-down) mpv_ipc '{ "command": ["add", "volume", -5] }' && echo "OK: volume down" || echo "Error" ;;
        seek-forward) mpv_ipc '{ "command": ["seek", 10, "relative"] }' && echo "OK: seek forward" || echo "Error" ;;
        seek-backward) mpv_ipc '{ "command": ["seek", -10, "relative"] }' && echo "OK: seek backward" || echo "Error" ;;
        mode) local newmode=$1; [[ "$newmode" != "audio" && "$newmode" != "video" ]] && { echo "Usage: ytpl player mode {audio|video}"; return 1; }; echo "$newmode" > "$YTPL_MODE"; echo "Mode switched to $newmode. Restart ytpl to apply." ;;
        show)
          local current="Unknown"; [[ -f "$YTPL_NOWPLAYING" ]] && current=$(cat "$YTPL_NOWPLAYING")
          echo "Current track: $current"
          local playlist_json pos
          playlist_json=$(printf '{ "command": ["get_property", "playlist"] }' | socat - "$YTPL_IPC" 2>/dev/null)
          pos=$(printf '{ "command": ["get_property", "playlist-pos"] }' | socat - "$YTPL_IPC" 2>/dev/null | jq -r '.data // empty' 2>/dev/null)
          if [[ -n "$playlist_json" && "$playlist_json" != "{}" ]]; then
            IFS=$'\n' read -r -d '' -A titles < <(echo "$playlist_json" | jq -r '.data[]?.filename' && printf '\0')
            local start=$(( pos - 2 < 0 ? 0 : pos - 2 )); local end=$(( pos + 3 >= ${#titles[@]} ? ${#titles[@]}-1 : pos + 3 ))
            echo "Queue context (prev 2 / current / next 3):"
            for i in $(seq $start $end); do if [[ $i -eq $pos ]]; then echo "▶ ${titles[$i]}"; else echo "  ${titles[$i]}"; fi; done
          else
            if [[ -f "$YTPL_QUEUE" ]]; then
              local -a qtitles urls; local idx=0 found=-1 total
              while IFS='|' read -r t u; do qtitles[idx]="$t"; urls[idx]="$u"; [[ "$t" == "$current" ]] && found=$idx; idx=$((idx+1)); done < "$YTPL_QUEUE"
              total=${#qtitles[@]}
              if [[ $found -eq -1 ]]; then echo "Queue available but current track not found in local queue."; return 0; fi
              local start=$(( found - 2 < 0 ? 0 : found - 2 )); local end=$(( found + 3 >= total ? total - 1 : found + 3 ))
              echo "Queue context (prev 2 / current / next 3):"
              for i in $(seq $start $end); do if [[ $i -eq $found ]]; then echo "▶ ${qtitles[$i]}"; else echo "  ${qtitles[$i]}"; fi; done
            else
              echo "Queue not available."
            fi
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
