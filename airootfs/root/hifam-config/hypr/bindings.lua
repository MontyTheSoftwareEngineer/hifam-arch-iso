---@module 'hl'

---------------------
---- MY PROGRAMS ----
---------------------
local mainMod = "SUPER" -- Sets "Windows" key as main modifier
local terminal      = "kitty"
local menu          = "hyprlauncher"
local browser       = "google-chrome-stable"
local screenshot    = "/usr/share/hifam/scripts/screenshot.sh"
local screenrecord  = "/usr/share/hifam/scripts/screenrecord.sh"

-- Application bindings
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))

hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))

-- hl.bind("SUPER" .. " + " .. "RETURN", hl.dsp.exec_cmd("kitty -e tmux new"))
-- hl.bind("SUPER + SHIFT" .. " + " .. "RETURN", hl.dsp.exec_cmd("kitty -e sh -c \"tmux attach || tmux new\""))


hl.bind("SUPER" .. " + " .. "P", hl.dsp.exec_cmd(screenshot))
hl.bind("SUPER + ALT" .. " + " .. "P", hl.dsp.exec_cmd(screenrecord))


hl.bind("SUPER" .. " + " .. "SPACE", hl.dsp.window.float())

-- hl.bind("SUPER" .. " + " .. "D", hl.dsp.exec_cmd("omarchy-menu toggle apps"))
-- hl.bind("SUPER + SHIFT" .. " + " .. "D", hl.dsp.exec_cmd("omarchy-menu toggle"))


hl.bind("SUPER + ALT + Q", hl.dsp.exec_cmd("~/.config/hypr/restart-mouseless.sh"))
hl.bind("SUPER + J", hl.dsp.exec_cmd("~/.config/hypr/wl-kbptr-click.sh"))
hl.bind("SUPER + I", hl.dsp.exec_cmd("~/.config/hypr/wl-kbptr-click.sh right"))
hl.bind("SUPER + H", hl.dsp.exec_cmd("~/.config/hypr/wl-kbptr-click.sh move"))

hl.bind("SUPER + SHIFT" .. " + " .. "F", hl.dsp.window.fullscreen())


hl.bind("SUPER + CTRL" .. " + " .. "L", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + CTRL" .. " + " .. "H", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + CTRL" .. " + " .. "J", hl.dsp.focus({ direction = "down" }))
hl.bind("SUPER + CTRL" .. " + " .. "K", hl.dsp.focus({ direction = "up" }))

-- hl.bind("SUPER + SHIFT" .. " + " .. "L", hl.dsp.exec_cmd("omarchy-system-lock"))


-- Lid switch bindings - handle suspend on close (unless external monitor) and wake on open

-- hl.unbind("switch:on:Lid Switch")
-- hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("~/.config/hypr/lid-close-handler.sh"), { locked = true })
--
-- hl.unbind("switch:off:Lid Switch")
-- hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("~/.config/hypr/lid-open-handler.sh"), { locked = true })

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
