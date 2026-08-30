#!/usr/bin/env bash
set -euo pipefail

app_id="net.sonuscape.mouseless"
unit_glob="app-flatpak-${app_id}-*.scope"

list_units() {
  systemctl --user list-units --all --plain --no-legend "$unit_glob" 2>/dev/null | awk '{print $1}'
}

list_pids() {
  flatpak ps --columns=application,pid 2>/dev/null | awk -v app="$app_id" '$1 == app { print $2 }'
}

wait_for_stop() {
  local attempts=$1

  for _ in $(seq 1 "$attempts"); do
    mapfile -t units < <(list_units)
    mapfile -t pids < <(list_pids)
    (( ${#units[@]} == 0 && ${#pids[@]} == 0 )) && return 0
    sleep 0.1
  done

  return 1
}

mapfile -t units < <(list_units)
if (( ${#units[@]} > 0 )); then
  systemctl --user stop "${units[@]}"
fi

mapfile -t pids < <(list_pids)
for pid in "${pids[@]}"; do
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid"
  fi
done

if ! wait_for_stop 50; then
  mapfile -t pids < <(list_pids)
  for pid in "${pids[@]}"; do
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      kill -9 "$pid"
    fi
  done
fi

if ! wait_for_stop 20; then
  mapfile -t units < <(list_units)
  mapfile -t pids < <(list_pids)
  echo "Failed to stop $app_id" >&2
  exit 1
fi

nohup flatpak run "$app_id" >/dev/null 2>&1 &
