```bash
#!/bin/bash

set -u

# Screenshot directory
if [[ -f ~/.config/user-dirs.dirs ]]; then
    source ~/.config/user-dirs.dirs
fi

OUTPUT_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"

mkdir -p "$OUTPUT_DIR"

SCREENSHOT_EDITOR="${SCREENSHOT_EDITOR:-satty}"

# Parse --editor flag
ARGS=()

for arg in "$@"; do
    if [[ "$arg" == --editor=* ]]; then
        SCREENSHOT_EDITOR="${arg#--editor=}"
    else
        ARGS+=("$arg")
    fi
done

set -- "${ARGS[@]}"

open_editor() {
    local filepath="$1"

    if [[ "$SCREENSHOT_EDITOR" == "satty" ]]; then
        satty \
            --filename "$filepath" \
            --output-filename "$filepath" \
            --actions-on-enter save-to-clipboard \
            --save-after-copy \
            --copy-command 'wl-copy'
    else
        "$SCREENSHOT_EDITOR" "$filepath"
    fi
}

MODE="${1:-smart}"
PROCESSING="${2:-slurp}"

# Handle portrait/transformed displays
JQ_MONITOR_GEO='
    def format_geo:
        .x as $x |
        .y as $y |
        (.width / .scale | floor) as $w |
        (.height / .scale | floor) as $h |
        .transform as $t |
        if $t == 1 or $t == 3 then
            "\($x),\($y) \($h)x\($w)"
        else
            "\($x),\($y) \($w)x\($h)"
        end;
'

get_rectangles() {
    local active_workspace

    active_workspace=$(
        hyprctl monitors -j |
        jq -r '.[] | select(.focused == true) | .activeWorkspace.id'
    )

    hyprctl monitors -j |
        jq -r --arg ws "$active_workspace" \
        "${JQ_MONITOR_GEO}
        .[] |
        select(.activeWorkspace.id == (\$ws | tonumber)) |
        format_geo"

    hyprctl clients -j |
        jq -r --arg ws "$active_workspace" \
        '.[] |
        select(.workspace.id == ($ws | tonumber)) |
        "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
}

cleanup_freeze() {
    if [[ -n "${PID:-}" ]]; then
        kill "$PID" 2>/dev/null
    fi
}

trap cleanup_freeze EXIT

case "$MODE" in

    region)
        hyprpicker -r -z >/dev/null 2>&1 &
        PID=$!

        sleep 0.1

        SELECTION=$(slurp 2>/dev/null)
        ;;

    windows)
        hyprpicker -r -z >/dev/null 2>&1 &
        PID=$!

        sleep 0.1

        SELECTION=$(get_rectangles | slurp -r 2>/dev/null)
        ;;

    fullscreen)
        SELECTION=$(
            hyprctl monitors -j |
            jq -r "${JQ_MONITOR_GEO}
                .[] |
                select(.focused == true) |
                format_geo"
        )
        ;;

    smart|*)
        RECTS=$(get_rectangles)

        hyprpicker -r -z >/dev/null 2>&1 &
        PID=$!

        sleep 0.1

        SELECTION=$(echo "$RECTS" | slurp 2>/dev/null)

        # If the selected area is extremely small,
        # assume the user clicked inside a window/output.
        if [[ "$SELECTION" =~ ^([0-9]+),([0-9]+)[[:space:]]([0-9]+)x([0-9]+)$ ]]; then

            if ((${BASH_REMATCH[3]} * ${BASH_REMATCH[4]} < 20)); then

                click_x="${BASH_REMATCH[1]}"
                click_y="${BASH_REMATCH[2]}"

                while IFS= read -r rect; do

                    if [[ "$rect" =~ ^([0-9]+),([0-9]+)[[:space:]]([0-9]+)x([0-9]+) ]]; then

                        rect_x="${BASH_REMATCH[1]}"
                        rect_y="${BASH_REMATCH[2]}"
                        rect_width="${BASH_REMATCH[3]}"
                        rect_height="${BASH_REMATCH[4]}"

                        if (( \
                            click_x >= rect_x &&
                            click_x < rect_x + rect_width &&
                            click_y >= rect_y &&
                            click_y < rect_y + rect_height
                        )); then

                            SELECTION="${rect_x},${rect_y} ${rect_width}x${rect_height}"
                            break

                        fi
                    fi

                done <<< "$RECTS"

            fi
        fi
        ;;

esac

# User cancelled selection
[[ -z "${SELECTION:-}" ]] && exit 0

FILENAME="screenshot-$(date '+%Y-%m-%d_%H-%M-%S').png"
FILEPATH="$OUTPUT_DIR/$FILENAME"

case "$PROCESSING" in

    slurp)
        grim -g "$SELECTION" "$FILEPATH" || exit 1

        echo "$FILEPATH"

        # Copy screenshot to clipboard
        wl-copy < "$FILEPATH"

        # Ask whether to edit
        (
            if command -v notify-send >/dev/null 2>&1; then
                ACTION=$(
                    notify-send \
                        "Screenshot saved" \
                        "Saved to clipboard and $FILEPATH" \
                        -t 10000 \
                        -i "$FILEPATH" \
                        -A "default=edit"
                )

                if [[ "$ACTION" == "default" ]] && command -v "$SCREENSHOT_EDITOR" >/dev/null 2>&1; then
                    open_editor "$FILEPATH"
                fi
            fi
        ) >/dev/null 2>&1 &
        ;;

    copy)
        grim -g "$SELECTION" - | wl-copy
        ;;

    save)
        grim -g "$SELECTION" "$FILEPATH" || exit 1
        echo "$FILEPATH"
        ;;

    *)
        echo "Unknown processing mode: $PROCESSING" >&2
        exit 1
        ;;

esac
```

