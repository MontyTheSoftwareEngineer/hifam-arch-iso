#!/usr/bin/env bash
set -euo pipefail

action="${1:-left}"
runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
lock_file="$runtime_dir/wl-kbptr-click.lock"
pid_file="$runtime_dir/wl-kbptr-click.pid"
action_file="$runtime_dir/wl-kbptr-click.action"
exec 9>"$lock_file"
flock 9

case "$action" in
  left)
    wl_kbptr_args=(
      -o modes=floating,click
      -o mode_floating.source=detect
      -o mode_click.button=left
      -o "mode_floating.label_font_size=18 100% 100"
    )
    ;;
  right)
    wl_kbptr_args=(
      -o modes=floating,click
      -o mode_floating.source=detect
      -o mode_click.button=right
      -o "mode_floating.label_font_size=18 50% 100"
    )
    ;;
  move)
    wl_kbptr_args=(
      -o modes=floating
      -o mode_floating.source=detect
      -o "mode_floating.label_font_size=18 50% 100"
    )
    ;;
  *)
    printf 'Unsupported wl-kbptr action: %s\n' "$action" >&2
    exit 1
    ;;
esac

if [[ -f "$pid_file" ]]; then
  pid="$(<"$pid_file")"
  if kill -0 "$pid" 2>/dev/null; then
    active_action="left"
    if [[ -f "$action_file" ]]; then
      active_action="$(<"$action_file")"
    fi
    kill "$pid"
    rm -f "$pid_file" "$action_file"
    if [[ "$active_action" == "$action" ]]; then
      exit 0
    fi
  fi
  rm -f "$pid_file" "$action_file"
fi

cleanup() {
  if [[ -f "$pid_file" ]] && [[ "$(<"$pid_file")" == "$wl_kbptr_pid" ]]; then
    rm -f "$pid_file" "$action_file"
  fi
}

wl-kbptr "${wl_kbptr_args[@]}" &
wl_kbptr_pid=$!
printf '%s\n' "$wl_kbptr_pid" > "$pid_file"
printf '%s\n' "$action" > "$action_file"

trap cleanup EXIT
flock -u 9
wait "$wl_kbptr_pid"

# exec wl-kbptr \
#   -o modes=floating,click \
#   -o mode_floating.source=detect \
#   -o "mode_floating.label_font_size=20 50% 100" \
#   -o "mode_floating.selectable_bg_color=#ffc6" \
#   -o "mode_floating.selectable_border_color=#edcc"
