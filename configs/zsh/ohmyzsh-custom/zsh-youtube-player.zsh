#!/usr/bin/env zsh
# YTPL - YouTube Playlist Audio/Video Daemon

pipx ensurepath > /dev/null 2>&1
pipx install yt-dlp > /dev/null 2>&1

YTPL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ytpl"
mkdir -p "$YTPL_DIR"

# Files
YTPL_PID="$YTPL_DIR/ytpl.pid"
YTPL_LOG="$YTPL_DIR/ytpl.log"
YTPL_NOWPLAYING="$YTPL_DIR/ytpl.nowplaying"
YTPL_IPC="$YTPL_DIR/ytpl.sock"
YTPL_LAST="$YTPL_DIR/last_playlist"
YTPL_MODE="$YTPL_DIR/mode"       # audio or video
YTPL_CONFIG="$YTPL_DIR/config"   # optional config file

# Default mode
[[ ! -f "$YTPL_MODE" ]] && echo "audio" > "$YTPL_MODE"

# Lua script for now playing + reset track start
YTPL_LUA="$YTPL_DIR/mpv_nowplaying.lua"
if [[ ! -f "$YTPL_LUA" ]]; then
cat > "$YTPL_LUA" <<'EOF'
local nowplaying_file = os.getenv("YTPL_NOWPLAYING") or "/tmp/ytpl.nowplaying"

mp.register_event("file-loaded", function()
    mp.set_property("time-pos", 0)  -- always start at beginning
    local title = mp.get_property("media-title")
    if title then
        local f = io.open(nowplaying_file, "w")
        if f then
            f:write(title .. "\n")
            f:close()
        end
    end
end)
EOF
fi

export YTPL_NOWPLAYING

ytpl() {
    local sub=$1
    shift

    if [[ -z "$sub" ]]; then
        echo "Usage: ytpl <command>

Commands:
  start <playlist_url>           Start playing a playlist
  stop                           Stop playback
  status                         Show daemon status
  logs                           Show last 30 lines of mpv logs
  player <command>               Control playback
"
        return
    fi

    case "$sub" in
        start)
            local url=$1
            [[ -z "$url" ]] && [[ -f "$YTPL_LAST" ]] && url=$(cat "$YTPL_LAST")
            if [[ -z "$url" ]]; then
                echo "Usage: ytpl start <playlist_url>"
                return 1
            fi

            # Normalize YouTube URL
            if [[ "$url" == *"list="* ]]; then
                local plist_id="${url#*list=}"
                plist_id="${plist_id%%&*}"
                url="https://www.youtube.com/playlist?list=$plist_id"
            fi

            if [[ -f "$YTPL_PID" ]] && kill -0 "$(cat "$YTPL_PID")" 2>/dev/null; then
                echo "ytpl is already running (PID $(cat "$YTPL_PID"))"
                return 1
            fi

            echo "$url" > "$YTPL_LAST"

            [[ -e "$YTPL_IPC" ]] && rm -f "$YTPL_IPC"
            [[ -f "$YTPL_NOWPLAYING" ]] && rm -f "$YTPL_NOWPLAYING"

            local mode_flag=""
            [[ "$(cat "$YTPL_MODE")" == "audio" ]] && mode_flag="--no-video"

            # Start mpv
            (
                mpv $mode_flag \
                    --ytdl=yes \
                    --ytdl-format="bestaudio/best" \
                    --loop-playlist=no \
                    --input-ipc-server="$YTPL_IPC" \
                    --idle=no \
                    --no-terminal \
                    --script="$YTPL_LUA" \
                    --save-position-on-quit=no \
                    --really-quiet \
                    "$url" \
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
            [[ -f "$YTPL_LOG" ]] && tail -n 30 "$YTPL_LOG" || echo "No logs found."
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
                    local current="Unknown"
                    [[ -f "$YTPL_NOWPLAYING" ]] && current=$(cat "$YTPL_NOWPLAYING")
                    echo "Current track: $current"

                    local playlist_json pos titles start end
                    playlist_json=$(printf '{ "command": ["get_property", "playlist"] }' | socat - "$YTPL_IPC")
                    pos=$(printf '{ "command": ["get_property", "playlist-pos"] }' | socat - "$YTPL_IPC" | jq '.data // 0')

                    if [[ -n "$playlist_json" && "$playlist_json" != "{}" ]]; then
                        titles=($(echo "$playlist_json" | jq -r '.data[]?.filename'))
                        start=$(( pos - 2 < 0 ? 0 : pos - 2 ))
                        end=$(( pos + 5 >= ${#titles[@]} ? ${#titles[@]}-1 : pos + 5 ))
                        echo "Queue context (prev 2 / current / next 5):"
                        for i in $(seq $start $end); do
                            [[ $i -eq $pos ]] && echo "▶ ${titles[$i]}" || echo "  ${titles[$i]}"
                        done
                    else
                        echo "Queue not available."
                    fi
                    ;;
                *)
                    echo "Usage: ytpl player <command>

Commands:
  play              Toggle playback (play/pause)
  pause             Toggle playback (play/pause)
  stop              Stop playback and quit mpv
  next              Skip to next song
  prev              Go to previous song
  volume-up         Increase volume by 5%
  volume-down       Decrease volume by 5%
  seek-forward      Seek forward 10 seconds
  seek-backward     Seek backward 10 seconds
  mode audio        Switch to audio-only mode (restart required)
  mode video        Switch to video mode (restart required)
  show              Display current track and queue context
"
                    ;;
            esac
            ;;
        *)
            echo "Usage: ytpl <command>

Commands:
  start <playlist_url>   Start playing a playlist
  stop                   Stop playback
  status                 Show daemon status
  logs                   Show last 30 lines of mpv logs
  player <command>       Control playback
"
            ;;
    esac
}
