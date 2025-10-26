#!/usr/bin/env zsh
# YTPL - YouTube Playlist Audio/Video Daemon

# Ensure yt-dlp is installed
pipx ensurepath > /dev/null 2>&1
pipx install yt-dlp > /dev/null 2>&1

# Directories and files
YTPL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ytpl"
mkdir -p "$YTPL_DIR"

YTPL_PID="$YTPL_DIR/ytpl.pid"
YTPL_LOG="/tmp/ytpl.log"
YTPL_NOWPLAYING="$YTPL_DIR/ytpl.nowplaying"
YTPL_IPC="$YTPL_DIR/ytpl.sock"
YTPL_LAST="$YTPL_DIR/last_playlist"
YTPL_MODE="$YTPL_DIR/mode"
YTPL_QUEUE="$YTPL_DIR/playlist.queue"
YTPL_LUA="$YTPL_DIR/mpv_nowplaying.lua"

[[ ! -f "$YTPL_MODE" ]] && echo "audio" > "$YTPL_MODE"

# Lua script for notifications + reset time-pos
if [[ ! -f "$YTPL_LUA" ]]; then
cat > "$YTPL_LUA" <<'EOF'
local nowplaying_file = os.getenv("YTPL_NOWPLAYING") or "/tmp/ytpl.nowplaying"
mp.register_event("file-loaded", function()
    mp.set_property("time-pos", 0)
    local title = mp.get_property("media-title")
    if title then
        local f = io.open(nowplaying_file, "w")
        if f then
            f:write(title .. "\n")
            f:close()
        end
        os.execute(string.format("notify-send 'Now Playing' '%s'", title:gsub("'", "'\\''")))
    end
end)
EOF
fi
export YTPL_NOWPLAYING

ytpl() {
    local sub=$1

    if [[ -z "$sub" ]]; then
cat <<'EOM'
Usage:
  ytpl start <playlist_url> [--shuffle] [--start N]
  ytpl stop
  ytpl status
  ytpl logs
  ytpl player <command>
EOM
        return
    fi

    shift

    case "$sub" in
        start)
            local url=""
            local shuffle_flag=""
            local start_index=""

            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --shuffle) shuffle_flag="--shuffle"; shift ;;
                    --start)
                        if [[ $# -le 1 ]]; then
                            echo "Error: --start requires an argument"
                            return 1
                        fi
                        start_index="--playlist-start=$2"
                        shift 2
                        ;;
                    *) url="$1"; shift ;;
                esac
            done

            [[ -z "$url" ]] && [[ -f "$YTPL_LAST" ]] && url=$(cat "$YTPL_LAST")
            if [[ -z "$url" ]]; then
                echo "Usage: ytpl start <playlist_url> [--shuffle] [--start N]"
                return 1
            fi

            # Normalize playlist URL
            if [[ "$url" =~ list=([^&]+) ]]; then
                url="https://music.youtube.com/playlist?list=${match[1]}"
            fi

            if [[ -f "$YTPL_PID" ]] && kill -0 "$(cat "$YTPL_PID")" 2>/dev/null; then
                echo "ytpl is already running (PID $(cat "$YTPL_PID"))"
                return 1
            fi

            echo "$url" > "$YTPL_LAST"
            [[ -e "$YTPL_IPC" ]] && rm -f "$YTPL_IPC"
            [[ -f "$YTPL_NOWPLAYING" ]] && rm -f "$YTPL_NOWPLAYING"
            > "$YTPL_LOG"

            echo "Building local queue..."
            yt-dlp -j --flat-playlist "$url" 2>/dev/null | jq -r '.title + "|" + .url' > "$YTPL_QUEUE" \
                || echo "$url" > "$YTPL_QUEUE"

            local mode_flag=""
            [[ "$(cat "$YTPL_MODE")" == "audio" ]] && mode_flag="--no-video"

            # Start mpv in background safely
            (
                stdbuf -oL -eL yt-dlp -o - "$url" | stdbuf -oL -eL mpv $mode_flag \
                    --ytdl-format="bestaudio/best" \
                    --loop-playlist=no \
                    --input-ipc-server="$YTPL_IPC" \
                    --idle=no \
                    --no-terminal \
                    --script="$YTPL_LUA" \
                    --save-position-on-quit=no \
                    --msg-level=all=info \
                    $shuffle_flag $start_index -
            ) >"$YTPL_LOG" 2>&1 &

            echo $! > "$YTPL_PID"
            echo "ytpl started in $(cat "$YTPL_MODE") mode (PID $(cat "$YTPL_PID"))"
            echo "Logs: $YTPL_LOG"
            echo "Now Playing: $YTPL_NOWPLAYING"
            ;;
        stop)
            if [[ -f "$YTPL_PID" ]]; then
                kill "$(cat "$YTPL_PID")" 2>/dev/null && echo "ytpl stopped" || echo "ytpl not running"
                rm -f "$YTPL_PID" "$YTPL_IPC" "$YTPL_NOWPLAYING"
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
            [[ -f "$YTPL_LOG" ]] && tail -n 50 -f "$YTPL_LOG" || echo "No logs found."
            ;;
        player)
            [[ -S "$YTPL_IPC" ]] || { echo "ytpl player: IPC socket not found. Is ytpl running?"; return 1; }
            local cmd=$1
            case "$cmd" in
                play|pause) echo '{ "command": ["cycle", "pause"] }' | socat - "$YTPL_IPC" ;;
                stop) echo '{ "command": ["quit"] }' | socat - "$YTPL_IPC" ;;
                next) echo '{ "command": ["playlist-next", "force"] }' | socat - "$YTPL_IPC" ;;
                prev) echo '{ "command": ["playlist-prev", "force"] }' | socat - "$YTPL_IPC" ;;
                volume-up) echo '{ "command": ["add", "volume", 5] }' | socat - "$YTPL_IPC" ;;
                volume-down) echo '{ "command": ["add", "volume", -5] }' | socat - "$YTPL_IPC" ;;
                seek-forward) echo '{ "command": ["seek", 10, "relative"] }' | socat - "$YTPL_IPC" ;;
                seek-backward) echo '{ "command": ["seek", -10, "relative"] }' | socat - "$YTPL_IPC" ;;
                mode)
                    local newmode=$2
                    [[ "$newmode" != "audio" && "$newmode" != "video" ]] && { echo "Usage: ytpl player mode {audio|video}"; return 1; }
                    echo "$newmode" > "$YTPL_MODE"
                    echo "Mode switched to $newmode. Restart ytpl to apply." ;;
                show)
                    local current="Unknown"
                    [[ -f "$YTPL_NOWPLAYING" ]] && current=$(cat "$YTPL_NOWPLAYING")
                    echo "Current track: $current"
                    if [[ -f "$YTPL_QUEUE" ]]; then
                        local i=0
                        echo "Queue:"
                        while IFS="|" read -r title url; do
                            echo "$i: $title"
                            ((i++))
                        done < "$YTPL_QUEUE"
                    fi
                    ;;
                *)
                    echo "ytpl player: Unknown command"
                    ;;
            esac
            ;;
        *)
            echo "Unknown subcommand: $sub"
            ;;
    esac
}
