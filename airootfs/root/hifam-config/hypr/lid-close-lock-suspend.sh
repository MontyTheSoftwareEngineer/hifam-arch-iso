#!/bin/bash
# Lid close: lock first, wait for the lock screen to render, then suspend.
# This ordering prevents briefly seeing the desktop on wake (logind's own
# lid-switch suspend is disabled via HandleLidSwitch=ignore in logind.conf,
# so this script is the sole handler).

qs ipc call lockscreen lock

# Give quickshell time to map/render the lock surface before we suspend.
sleep 1

systemctl suspend
