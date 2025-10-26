#!/usr/bin/env zsh
# YTPL - YouTube Playlist Audio/Video Daemon

pipx ensurepath &> /dev/null

pipx install yt-dlp &> /dev/null

# YTPL - YouTube Playlist Audio/Video Daemon
YTPL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ytpl"
mkdir -p "$YTPL_DIR"

# Files
YTPL_PID="$YTPL_DIR/ytpl.pid"
YTPL_LOG="/tmp/ytpl.log"             # moved to /tmp to avoid bloating
YTPL_NOWPLAYING="$YTPL_DIR/ytpl.nowplaying"
YTPL_IPC="$YTPL_DIR/ytpl.sock"
YTPL_LAST="$YTPL_DIR/last_playlist"
YTPL_MODE="$YTPL_DIR/mode"           # audio or video
YTPL_CONFIG="$YTPL_DIR/config"       # optional config file

# Default mode
[[ ! -f "$YTPL_MODE" ]] && echo "audio" > "$YTPL_MODE"

# Ensure Lua script exists
YTPL_LUA="$YTPL_DIR/mpv_nowplaying.lua"
if [[ ! -f "$YTPL_LUA" ]]; then
cat > "$YTPL_LUA" <<'EOF'
-- writes current track title to file and sends desktop notification
local nowplaying_file = os.getenv("YTPL_NOWPLAYING") or "/tmp/ytpl.nowplaying"

mp.register_event("file-loaded", function()
    local title = mp.get_property("media-title")
    if title then
        local f = io.open(nowplaying_file, "w")
        if f then
            f:write(title .. "\n")
            f:close()
        end
        -- send desktop notification
        os.execute(string.format("notify-send 'Now Playing' '%s'", title:gsub("'", "'\\''")))
    end
end)
EOF
fi

export YTPL_NOWPLAYING

ytpl() {
    local sub=$1
    shift

    case "$sub" in
        start)
            local url=""
            local shuffle_flag=""
            local start_index=""
            # Parse arguments
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --shuffle) shuffle_flag="--shuffle"; shift ;;
                    --start) start_index="--playlist-start=$2"; shift 2 ;;
                    *) url="$1"; shift ;;
                esac
            done

            [[ -z "$url" ]] && [[ -f "$YTPL_LAST" ]] && url=$(cat "$YTPL_LAST")
            if [[ -z "$url" ]]; then
                echo "Usage: ytpl start <playlist_url> [--shuffle] [--start N]"
                return 1
            fi

            # Normalize YouTube Music playlist URLs
            if [[ "$url" =~ list=([^&]+) ]]; then
                url="https://music.youtube.com/playlist?list=${BASH_REMATCH[1]}"
            fi

            if [[ -f "$YTPL_PID" ]] && kill -0 "$(cat "$YTPL_PID")" 2>/dev/null; then
                echo "ytpl is already running (PID $(cat "$YTPL_PID"))"
                return 1
            fi

            echo "$url" > "$YTPL_LAST"

            # Remove old IPC & Now Playing
            [[ -e "$YTPL_IPC" ]] && rm -f "$YTPL_IPC"
            [[ -f "$YTPL_NOWPLAYING" ]] && rm -f "$YTPL_NOWPLAYING"

            # Clear old log
            > "$YTPL_LOG"

            # Determine mode
            local mode_flag=""
            if [[ "$(cat "$YTPL_MODE")" == "audio" ]]; then
                mode_flag="--no-video"
            fi

            # Start mpv with proper logging, shuffle, and start index
            mpv $mode_flag \
                --ytdl=yes \
                --ytdl-format="bestaudio/best" \
                --ytdl-raw-options=yes-playlist=yes \
                --loop-playlist=no \
                --input-ipc-server="$YTPL_IPC" \
                --idle=no \
                --no-terminal \
                --script="$YTPL_LUA" \
                --save-position-on-quit=no \
                --msg-level=all=info \
                $shuffle_flag \
                $start_index \
                "$url" \
                >"$YTPL_LOG" 2>&1 &
            echo $! > "$YTPL_PID"

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
                    echo '{ "command": ["set_property", "time-pos", 0] }' | socat - "$YTPL_IPC"
                    ;;
                prev)
                    echo '{ "command": ["playlist-prev", "force"] }' | socat - "$YTPL_IPC"
                    echo '{ "command": ["set_property", "time-pos", 0] }' | socat - "$YTPL_IPC"
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
                    # Show now playing + queue context
                    if [[ ! -S "$YTPL_IPC" ]]; then
                        echo "ytpl is not running."
                        return 1
                    fi

                    local current="Unknown"
                    [[ -f "$YTPL_NOWPLAYING" ]] && current=$(cat "$YTPL_NOWPLAYING")

                    local playlist_json pos
                    playlist_json=$(printf '{ "command": ["get_property", "playlist"] }' | socat - "$YTPL_IPC")
                    pos=$(printf '{ "command": ["get_property", "playlist-pos"] }' | socat - "$YTPL_IPC" | jq '.data')

                    if [[ -n "$playlist_json" && "$playlist_json" != "{}" ]]; then
                        local titles=($(echo "$playlist_json" | jq -r '.data[]?.filename'))
                        local start=$(( pos - 2 < 0 ? 0 : pos - 2 ))
                        local end=$(( pos + 5 >= ${#titles[@]} ? ${#titles[@]}-1 : pos + 5 ))
                        echo "Queue context (prev 2 / current / next 5):"
                        for i in $(seq $start $end); do
                            if [[ $i -eq $pos ]]; then
                                echo "▶ ${titles[$i]}"
                            else
                                echo "  ${titles[$i]}"
                            fi
                        done
                    else
                        echo "Current track: $current"
                        echo "Queue not available."
                    fi
                    ;;
                *)
                    cat <<'EOM'
Usage: ytpl player <command> [options]

Commands:
  play              Toggle playback (play/pause)
  pause             Toggle playback (play/pause)
  stop              Stop playback and quit mpv
  next              Skip to next song (starts at 0:00)
  prev              Go to previous song (starts at 0:00)
  volume-up         Increase volume by 5%
  volume-down       Decrease volume by 5%
  seek-forward      Seek forward 10 seconds
  seek-backward     Seek backward 10 seconds
  mode audio        Switch to audio-only mode (restart required)
  mode video        Switch to video mode (restart required)
  show              Display current track and queue context
EOM
                    ;;
            esac
            ;;
            # Default usage (for main command)
            *)
            cat <<'EOM'
Usage:
    ytpl start <playlist_url> [--shuffle] [--start N]  
        Start playing a playlist.
        --shuffle       Play the playlist in random order.
        --start N       Start from the N-th video (0-based index).

    ytpl stop
        Stop playback and quit mpv.

    ytpl status
        Show current daemon status (running or not, mode).

    ytpl logs
        Show the last 30 lines of mpv logs.

    ytpl player <command> [options]
        Control playback and see queue.

EOM
            ;;
    esac
}
